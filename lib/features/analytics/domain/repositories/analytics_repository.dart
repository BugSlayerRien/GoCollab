import '../../../../core/utils/result.dart';
import '../entities/analytics_snapshot.dart';

abstract class AnalyticsRepository {
  Future<Result<AnalyticsSnapshot>> getSnapshot();
}
