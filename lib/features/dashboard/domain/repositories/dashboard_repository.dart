import '../../../../core/utils/result.dart';
import '../entities/community_stats.dart';

abstract class DashboardRepository {
  Future<Result<CommunityStats>> getCommunityStats(String userId);
}
