import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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

class SavedOpportunityController extends StateNotifier<bool> {
  SavedOpportunityController(this._ref) : super(false);
  final Ref _ref;

  Future<void> toggle(Opportunity opportunity) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    state = true;
    final repository = _ref.read(opportunityRepositoryProvider);
    await repository.toggleSaved(
      opportunityId: opportunity.id,
      userId: user.id,
      save: !opportunity.isSaved,
    );
    state = false;
    _ref.invalidate(opportunitiesListProvider);
    _ref.invalidate(opportunityDetailProvider(opportunity.id));
    _ref.invalidate(savedOpportunitiesProvider);
  }
}

final savedOpportunityControllerProvider =
    StateNotifierProvider.autoDispose<SavedOpportunityController, bool>((ref) => SavedOpportunityController(ref));

class CreateOpportunityController extends StateNotifier<bool> {
  CreateOpportunityController(this._ref) : super(false);
  final Ref _ref;

  Future<bool> create({
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
    if (result.isSuccess) _ref.invalidate(opportunitiesListProvider);
    return result.isSuccess;
  }
}

final createOpportunityControllerProvider =
    StateNotifierProvider.autoDispose<CreateOpportunityController, bool>((ref) => CreateOpportunityController(ref));
