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

  Future<String?> createPartner(Partner partner) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createPartner(partner);
    state = false;
    if (result.isSuccess) _ref.invalidate(partnersListProvider);
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  /// Quick-add from the event editor. Returns the new partner id on
  /// success, or null on failure (with [errorOut] set, if provided).
  Future<String?> createPartnerMinimal({
    required String name,
    required PartnerCategory category,
    void Function(String)? onError,
  }) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createPartnerMinimal(name: name, category: category);
    state = false;
    if (result.isSuccess) _ref.invalidate(partnersListProvider);
    return result.when(
      success: (id) => id,
      failure: (f) {
        onError?.call(f.message);
        return null;
      },
    );
  }

  Future<String?> updatePartner(Partner partner) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.updatePartner(partner);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(partnersListProvider);
      _ref.invalidate(partnerDetailProvider(partner.id));
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> deletePartner(String id) async {
    state = true;
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.deletePartner(id);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(partnersListProvider);
      _ref.invalidate(partnerDetailProvider(id));
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
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

  Future<String?> createMeeting(Meeting meeting) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createMeeting(meeting);
    if (result.isSuccess) _ref.invalidate(meetingsProvider(meeting.partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> updateMeeting(Meeting meeting) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.updateMeeting(meeting);
    if (result.isSuccess) _ref.invalidate(meetingsProvider(meeting.partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> deleteMeeting(String id, String partnerId) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.deleteMeeting(id);
    if (result.isSuccess) _ref.invalidate(meetingsProvider(partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> createSponsorship(Sponsorship sponsorship) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createSponsorship(sponsorship);
    if (result.isSuccess) _ref.invalidate(sponsorshipsProvider(sponsorship.partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> updateSponsorship(Sponsorship sponsorship) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.updateSponsorship(sponsorship);
    if (result.isSuccess) _ref.invalidate(sponsorshipsProvider(sponsorship.partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> deleteSponsorship(String id, String partnerId) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.deleteSponsorship(id);
    if (result.isSuccess) _ref.invalidate(sponsorshipsProvider(partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> createCommunication({
    required String partnerId,
    required String subject,
    String? message,
    required String direction,
    required String contactMethod,
    required String communicatedBy,
  }) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.createCommunication(
      partnerId: partnerId,
      subject: subject,
      message: message,
      direction: direction,
      contactMethod: contactMethod,
      communicatedBy: communicatedBy,
    );
    if (result.isSuccess) _ref.invalidate(communicationsProvider(partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> updateCommunication(CommunicationLog log) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.updateCommunication(log);
    if (result.isSuccess) _ref.invalidate(communicationsProvider(log.partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> deleteCommunication(String id, String partnerId) async {
    final repository = _ref.read(partnershipRepositoryProvider);
    final result = await repository.deleteCommunication(id);
    if (result.isSuccess) _ref.invalidate(communicationsProvider(partnerId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final partnershipActionsControllerProvider =
    StateNotifierProvider<PartnershipActionsController, bool>((ref) => PartnershipActionsController(ref));
