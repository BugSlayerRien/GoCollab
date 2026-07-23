import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../data/datasources/analytics_remote_datasource.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/entities/analytics_snapshot.dart';
import '../../domain/repositories/analytics_repository.dart';

final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>((ref) {
  return AnalyticsRemoteDataSource(ref.watch(supabaseClientProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(analyticsRemoteDataSourceProvider));
});

final analyticsSnapshotProvider = FutureProvider.autoDispose<AnalyticsSnapshot>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getSnapshot();
  return result.when(success: (data) => data, failure: (f) => throw f);
});
