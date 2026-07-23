import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../data/datasources/partnership_remote_datasource.dart';
import '../../data/repositories/partnership_repository_impl.dart';
import '../../domain/entities/communication_log.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/partner.dart';
import '../../domain/entities/sponsorship.dart';
import '../../domain/repositories/partnership_repository.dart';

final partnershipRemoteDataSourceProvider = Provider<PartnershipRemoteDataSource>((ref) {
  return PartnershipRemoteDataSource(ref.watch(supabaseClientProvider));
});

final partnershipRepositoryProvider = Provider<PartnershipRepository>((ref) {
  return PartnershipRepositoryImpl(ref.watch(partnershipRemoteDataSourceProvider));
});

final partnersListProvider = FutureProvider.autoDispose<List<Partner>>((ref) async {
  final repository = ref.watch(partnershipRepositoryProvider);
  final result = await repository.getPartners();
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final partnerDetailProvider = FutureProvider.autoDispose.family<Partner, String>((ref, id) async {
  final repository = ref.watch(partnershipRepositoryProvider);
  final result = await repository.getPartnerById(id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final sponsorshipsProvider = FutureProvider.autoDispose.family<List<Sponsorship>, String>((ref, partnerId) async {
  final repository = ref.watch(partnershipRepositoryProvider);
  final result = await repository.getSponsorships(partnerId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final meetingsProvider = FutureProvider.autoDispose.family<List<Meeting>, String>((ref, partnerId) async {
  final repository = ref.watch(partnershipRepositoryProvider);
  final result = await repository.getMeetings(partnerId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final communicationsProvider = FutureProvider.autoDispose.family<List<CommunicationLog>, String>((ref, partnerId) async {
  final repository = ref.watch(partnershipRepositoryProvider);
  final result = await repository.getCommunications(partnerId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

class PartnershipActionsController extends StateNotifier<bool> {
  PartnershipActionsController(this._ref) : super(false);
  final Ref _ref;

  Future<bool> createPartner(Partner partner) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createPartner(partner);
    state = false;
    if (result.isSuccess) _ref.invalidate(partnersListProvider);
    return result.isSuccess;
  }

  Future<bool> updateStatus(String partnerId, CollaborationStatus status) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.updateCollaborationStatus(partnerId, status);
    if (result.isSuccess) {
      _ref.invalidate(partnersListProvider);
      _ref.invalidate(partnerDetailProvider(partnerId));
    }
    return result.isSuccess;
  }

  Future<bool> createMeeting(Meeting meeting) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createMeeting(meeting);
    state = false;
    if (result.isSuccess) _ref.invalidate(meetingsProvider(meeting.partnerId));
    return result.isSuccess;
  }

  Future<bool> createSponsorship(Sponsorship sponsorship) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createSponsorship(sponsorship);
    state = false;
    if (result.isSuccess) _ref.invalidate(sponsorshipsProvider(sponsorship.partnerId));
    return result.isSuccess;
  }

  Future<bool> createCommunication({
    required String partnerId,
    required String subject,
    String? message,
    required String direction,
    required String contactMethod,
    required String communicatedBy,
  }) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createCommunication(
      partnerId: partnerId,
      subject: subject,
      message: message,
      direction: direction,
      contactMethod: contactMethod,
      communicatedBy: communicatedBy,
    );
    state = false;
    if (result.isSuccess) _ref.invalidate(communicationsProvider(partnerId));
    return result.isSuccess;
  }
}

final partnershipActionsControllerProvider =
    StateNotifierProvider.autoDispose<PartnershipActionsController, bool>((ref) => PartnershipActionsController(ref));
