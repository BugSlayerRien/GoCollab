import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/communication_log.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/partner.dart';
import '../../domain/entities/sponsorship.dart';
import '../../domain/repositories/partnership_repository.dart';
import '../datasources/partnership_remote_datasource.dart';
import '../models/partner_model.dart';

class PartnershipRepositoryImpl implements PartnershipRepository {
  PartnershipRepositoryImpl(this._dataSource);
  final PartnershipRemoteDataSource _dataSource;

  @override
  Future<Result<List<Partner>>> getPartners() async {
    try {
      return Result.success(await _dataSource.getPartners());
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Partner>> getPartnerById(String id) async {
    try {
      return Result.success(await _dataSource.getPartnerById(id));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> createPartner(Partner partner) async {
    try {
      final model = PartnerModel(
        id: partner.id,
        name: partner.name,
        category: partner.category,
        collaborationStatus: partner.collaborationStatus,
        logoUrl: partner.logoUrl,
        description: partner.description,
        contactPerson: partner.contactPerson,
        contactEmail: partner.contactEmail,
        contactPhone: partner.contactPhone,
        address: partner.address,
        latitude: partner.latitude,
        longitude: partner.longitude,
        website: partner.website,
      );
      await _dataSource.createPartner(model);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> updateCollaborationStatus(String partnerId, CollaborationStatus status) async {
    try {
      await _dataSource.updateCollaborationStatus(partnerId, status);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<Sponsorship>>> getSponsorships(String partnerId) async {
    try {
      return Result.success(await _dataSource.getSponsorships(partnerId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> createSponsorship(Sponsorship sponsorship) async {
    try {
      await _dataSource.createSponsorship({
        'partner_id': sponsorship.partnerId,
        'title': sponsorship.title,
        'sponsorship_type': sponsorship.sponsorshipType,
        'status': sponsorship.status,
        'amount': sponsorship.amount,
        'currency': sponsorship.currency,
        'start_date': sponsorship.startDate?.toIso8601String(),
        'end_date': sponsorship.endDate?.toIso8601String(),
        'notes': sponsorship.notes,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<Meeting>>> getMeetings(String partnerId) async {
    try {
      return Result.success(await _dataSource.getMeetings(partnerId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> createMeeting(Meeting meeting) async {
    try {
      await _dataSource.createMeeting({
        'partner_id': meeting.partnerId,
        'title': meeting.title,
        'agenda': meeting.agenda,
        'scheduled_at': meeting.scheduledAt.toIso8601String(),
        'location': meeting.location,
        'status': meeting.status,
        'notes': meeting.notes,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<List<CommunicationLog>>> getCommunications(String partnerId) async {
    try {
      return Result.success(await _dataSource.getCommunications(partnerId));
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> createCommunication({
    required String partnerId,
    required String subject,
    String? message,
    required String direction,
    required String contactMethod,
    required String communicatedBy,
  }) async {
    try {
      await _dataSource.createCommunication(
        partnerId: partnerId,
        subject: subject,
        message: message,
        direction: direction,
        contactMethod: contactMethod,
        communicatedBy: communicatedBy,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
