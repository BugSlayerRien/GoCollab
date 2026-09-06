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

  /// Self-report "I applied" so there is an in-app record and the member can
  /// find their way back to it later. GoCollab cannot verify the external
  /// application itself — see [getOpportunityById]'s `applicants` list for
  /// the officer-visible follow-up mechanism.
  Future<Result<void>> markApplied({
    required String opportunityId,
    required String userId,
    String? note,
  });

  /// Opportunities the current user has self-reported applying to, so they
  /// can come back and re-open the external application later.
  Future<Result<List<Opportunity>>> getAppliedOpportunities(String userId);

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

  Future<Result<void>> updateOpportunity({
    required String id,
    required String title,
    required String organization,
    required OpportunityType type,
    required String description,
    String? requirements,
    String? location,
    required bool isRemote,
    String? applicationUrl,
    DateTime? deadline,
    required String status,
  });

  Future<Result<void>> deleteOpportunity(String id);
}
