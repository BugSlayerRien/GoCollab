import '../../../../core/utils/result.dart';
import '../entities/opportunity.dart';

abstract class OpportunityRepository {
  Future<Result<List<Opportunity>>> getOpportunities({String? currentUserId});

  Future<Result<Opportunity>> getOpportunityById(String id, {String? currentUserId});

  Future<Result<void>> toggleSaved({
    required String opportunityId,
    required String userId,
    required bool save,
  });

  Future<Result<List<Opportunity>>> getSavedOpportunities(String userId);

  Future<Result<void>> createOpportunity({
    required String title,
    required String organization,
    required OpportunityType type,
    required String description,
    String? requirements,
    String? location,
    required bool isRemote,
    String? applicationUrl,
    DateTime? deadline,
    required String postedBy,
  });
}
