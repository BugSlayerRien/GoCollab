import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/opportunity_remote_datasource.dart';
import '../../data/repositories/opportunity_repository_impl.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/repositories/opportunity_repository.dart';

final opportunityRemoteDataSourceProvider = Provider<OpportunityRemoteDataSource>((ref) {
  return OpportunityRemoteDataSource(ref.watch(supabaseClientProvider));
});

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return OpportunityRepositoryImpl(ref.watch(opportunityRemoteDataSourceProvider));
});

final opportunitiesListProvider = FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final repository = ref.watch(opportunityRepositoryProvider);
  final result = await repository.getOpportunities(currentUserId: currentUser?.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final opportunityDetailProvider = FutureProvider.autoDispose.family<Opportunity, String>((ref, id) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final repository = ref.watch(opportunityRepositoryProvider);
  final result = await repository.getOpportunityById(id, currentUserId: currentUser?.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final savedOpportunitiesProvider = FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  final repository = ref.watch(opportunityRepositoryProvider);
  final result = await repository.getSavedOpportunities(currentUser.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

/// Opportunities the current user has self-reported applying to — lets them
/// find their way back to an application after leaving to the external site.
final appliedOpportunitiesProvider = FutureProvider.autoDispose<List<Opportunity>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return [];
  final repository = ref.watch(opportunityRepositoryProvider);
  final result = await repository.getAppliedOpportunities(currentUser.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

class ApplyOpportunityController extends StateNotifier<bool> {
  ApplyOpportunityController(this._ref) : super(false);
  final Ref _ref;

  Future<String?> markApplied(Opportunity opportunity, {String? note}) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final repository = _ref.read(opportunityRepositoryProvider);
    final result = await repository.markApplied(opportunityId: opportunity.id, userId: user.id, note: note);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(opportunitiesListProvider);
      _ref.invalidate(opportunityDetailProvider(opportunity.id));
      _ref.invalidate(appliedOpportunitiesProvider);
      _ref.invalidate(communityPointsProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final applyOpportunityControllerProvider =
    StateNotifierProvider<ApplyOpportunityController, bool>((ref) => ApplyOpportunityController(ref));

class SavedOpportunityController extends StateNotifier<bool> {
  SavedOpportunityController(this._ref) : super(false);
  final Ref _ref;

  Future<String?> toggle(Opportunity opportunity) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    final repository = _ref.read(opportunityRepositoryProvider);
    final result = await repository.toggleSaved(
      opportunityId: opportunity.id,
      userId: user.id,
      save: !opportunity.isSaved,
    );
    if (result.isSuccess) {
      _ref.invalidate(opportunitiesListProvider);
      _ref.invalidate(opportunityDetailProvider(opportunity.id));
      _ref.invalidate(savedOpportunitiesProvider);
      _ref.invalidate(communityPointsProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final savedOpportunityControllerProvider =
    StateNotifierProvider<SavedOpportunityController, bool>((ref) => SavedOpportunityController(ref));

class CreateOpportunityController extends StateNotifier<bool> {
  CreateOpportunityController(this._ref) : super(false);
  final Ref _ref;

  Future<String?> create({
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
  }) async {
    state = true;
    final repository = _ref.read(opportunityRepositoryProvider);
    final result = await repository.createOpportunity(
      title: title,
      organization: organization,
      type: type,
      description: description,
      requirements: requirements,
      location: location,
      isRemote: isRemote,
      applicationUrl: applicationUrl,
      deadline: deadline,
      postedBy: postedBy,
    );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(opportunitiesListProvider);
      _ref.invalidate(notificationsProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> update({
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
  }) async {
    state = true;
    final repository = _ref.read(opportunityRepositoryProvider);
    final result = await repository.updateOpportunity(
      id: id,
      title: title,
      organization: organization,
      type: type,
      description: description,
      requirements: requirements,
      location: location,
      isRemote: isRemote,
      applicationUrl: applicationUrl,
      deadline: deadline,
      status: status,
    );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(opportunitiesListProvider);
      _ref.invalidate(opportunityDetailProvider(id));
      _ref.invalidate(savedOpportunitiesProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> delete(String id) async {
    state = true;
    final repository = _ref.read(opportunityRepositoryProvider);
    final result = await repository.deleteOpportunity(id);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(opportunitiesListProvider);
      _ref.invalidate(opportunityDetailProvider(id));
      _ref.invalidate(savedOpportunitiesProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final createOpportunityControllerProvider =
    StateNotifierProvider<CreateOpportunityController, bool>((ref) => CreateOpportunityController(ref));
