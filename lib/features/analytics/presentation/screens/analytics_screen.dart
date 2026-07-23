import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/analytics_snapshot.dart';
import '../providers/analytics_providers.dart';
import '../widgets/stat_summary_card.dart';

/// Officer-only "Community Analytics" module (#5): active members,
/// attendance, engagement, event performance, and growth statistics,
/// rendered with `fl_chart`.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(analyticsSnapshotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Analytics')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(analyticsSnapshotProvider),
        child: snapshotAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorStateView(
            message: 'Could not load analytics.',
            onRetry: () => ref.invalidate(analyticsSnapshotProvider),
          ),
          data: (snapshot) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.5,
                children: [
                  StatSummaryCard(
                    label: 'Active members',
                    value: '${snapshot.activeMembers}/${snapshot.totalMembers}',
                    icon: Icons.groups_rounded,
                    color: AppColors.googleBlue,
                  ),
                  StatSummaryCard(
                    label: 'Total events',
                    value: '${snapshot.totalEvents}',
                    icon: Icons.event_rounded,
                    color: AppColors.googleYellow,
                  ),
                  StatSummaryCard(
                    label: 'Avg. attendance',
                    value: '${(snapshot.averageAttendanceRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.googleGreen,
                  ),
                  StatSummaryCard(
                    label: 'Engagement actions',
                    value: '${snapshot.totalEngagementActions}',
                    icon: Icons.bolt_rounded,
                    color: AppColors.googleRed,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Member growth (last 6 months)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _GrowthChart(points: snapshot.growth),
              const SizedBox(height: AppSpacing.xl),
              Text('Event performance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              snapshot.eventPerformance.isEmpty
                  ? const EmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'No event data yet',
                      message: 'Attendance charts will appear once events start collecting registrations.',
                    )
                  : _EventPerformanceChart(data: snapshot.eventPerformance),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.points});
  final List<GrowthPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = points.map((p) => p.newMembers).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY + 2).toDouble(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('MMM').format(points[index].month), style: Theme.of(context).textTheme.labelSmall),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].newMembers.toDouble())],
              isCurved: true,
              color: AppColors.googleBlue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.googleBlue.withValues(alpha: 0.12)),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class _EventPerformanceChart extends StatelessWidget {
  const _EventPerformanceChart({required this.data});
  final List<EventPerformance> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((d) => d.registered).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      height: 240,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: (maxY + 2).toDouble(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  final title = data[index].eventTitle;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      title.length > 8 ? '${title.substring(0, 8)}…' : title,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: data[i].registered.toDouble(), color: AppColors.googleBlue, width: 8, borderRadius: BorderRadius.circular(4)),
                BarChartRodData(toY: data[i].attended.toDouble(), color: AppColors.googleGreen, width: 8, borderRadius: BorderRadius.circular(4)),
              ]),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
