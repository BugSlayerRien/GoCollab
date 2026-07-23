import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/community_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(supabaseClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final communityStatsProvider = FutureProvider.autoDispose<CommunityStats?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getCommunityStats(user.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});
