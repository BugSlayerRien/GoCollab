import '../../../../core/utils/result.dart';
import '../entities/communication_log.dart';
import '../entities/meeting.dart';
import '../entities/partner.dart';
import '../entities/sponsorship.dart';

abstract class PartnershipRepository {
  Future<Result<List<Partner>>> getPartners();

  Future<Result<Partner>> getPartnerById(String id);

  Future<Result<void>> createPartner(Partner partner);

  /// Quick-add from the event editor's inline "New partner" flow. Returns
  /// the new partner's id so the event form can auto-select it.
  Future<Result<String>> createPartnerMinimal({required String name, required PartnerCategory category});

  Future<Result<void>> updatePartner(Partner partner);

  Future<Result<void>> deletePartner(String id);

  Future<Result<void>> updateCollaborationStatus(String partnerId, CollaborationStatus status);

  Future<Result<List<Sponsorship>>> getSponsorships(String partnerId);

  Future<Result<void>> createSponsorship(Sponsorship sponsorship);

  Future<Result<void>> updateSponsorship(Sponsorship sponsorship);

  Future<Result<void>> deleteSponsorship(String id);

  Future<Result<List<Meeting>>> getMeetings(String partnerId);

  Future<Result<void>> createMeeting(Meeting meeting);

  Future<Result<void>> updateMeeting(Meeting meeting);

  Future<Result<void>> deleteMeeting(String id);

  Future<Result<List<CommunicationLog>>> getCommunications(String partnerId);

  Future<Result<void>> createCommunication({
    required String partnerId,
    required String subject,
    String? message,
    required String direction,
    required String contactMethod,
    required String communicatedBy,
  });

  Future<Result<void>> updateCommunication(CommunicationLog log);

  Future<Result<void>> deleteCommunication(String id);
}
