import '../../../../core/utils/result.dart';
import '../entities/communication_log.dart';
import '../entities/meeting.dart';
import '../entities/partner.dart';
import '../entities/sponsorship.dart';

abstract class PartnershipRepository {
  Future<Result<List<Partner>>> getPartners();

  Future<Result<Partner>> getPartnerById(String id);

  Future<Result<void>> createPartner(Partner partner);

  Future<Result<void>> updateCollaborationStatus(String partnerId, CollaborationStatus status);

  Future<Result<List<Sponsorship>>> getSponsorships(String partnerId);

  Future<Result<void>> createSponsorship(Sponsorship sponsorship);

  Future<Result<List<Meeting>>> getMeetings(String partnerId);

  Future<Result<void>> createMeeting(Meeting meeting);

  Future<Result<List<CommunicationLog>>> getCommunications(String partnerId);

  Future<Result<void>> createCommunication({
    required String partnerId,
    required String subject,
    String? message,
    required String direction,
    required String contactMethod,
    required String communicatedBy,
  });
}
