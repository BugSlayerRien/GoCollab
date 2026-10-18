import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/analytics/presentation/widgets/stat_summary_card.dart';
import 'package:gocollab/features/dashboard/presentation/widgets/quick_actions_grid.dart';

Widget _host(Widget child, {double scale = 1.2}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(360, 740), textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('stat cards and quick actions survive a large text scale', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(
      ListView(children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          childAspectRatio: 1.6 / 1.2,
          children: const [
            StatSummaryCard(label: 'Active members', value: '3', icon: Icons.groups_rounded, color: Colors.blue),
            StatSummaryCard(label: 'Avg. attendance', value: '0%', icon: Icons.check, color: Colors.green),
          ],
        ),
        QuickActionsGrid(actions: [
          for (final l in ['My Calendar', 'Events', 'Career Hub', 'Community'])
            QuickAction(icon: Icons.event, label: l, color: Colors.red, onTap: () {}),
        ]),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });
}
