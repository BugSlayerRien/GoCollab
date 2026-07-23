import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/opportunity.dart';
import '../models/opportunity_model.dart';

class OpportunityRemoteDataSource {
  OpportunityRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<OpportunityModel>> getOpportunities({String? currentUserId}) async {
    final rows = await _client.from('opportunities').select().order('deadline');

    Set<String> savedIds = {};
    if (currentUserId != null) {
      final savedRows =
          await _client.from('saved_opportunities').select('opportunity_id').eq('user_id', currentUserId);
      savedIds = (savedRows as List).map((r) => r['opportunity_id'] as String).toSet();
    }

    return (rows as List)
        .map((row) => OpportunityModel.fromMap(
              row as Map<String, dynamic>,
              isSaved: savedIds.contains(row['id']),
            ))
        .toList();
  }

  Future<OpportunityModel> getOpportunityById(String id, {String? currentUserId}) async {
    final row = await _client.from('opportunities').select().eq('id', id).single();

    bool isSaved = false;
    if (currentUserId != null) {
      final saved = await _client
          .from('saved_opportunities')
          .select('id')
          .eq('opportunity_id', id)
          .eq('user_id', currentUserId)
          .maybeSingle();
      isSaved = saved != null;
    }
    return OpportunityModel.fromMap(row, isSaved: isSaved);
  }

  Future<void> toggleSaved({required String opportunityId, required String userId, required bool save}) async {
    if (save) {
      await _client.from('saved_opportunities').upsert(
        {'opportunity_id': opportunityId, 'user_id': userId},
        onConflict: 'user_id,opportunity_id',
      );
      await _client.from('engagement_logs').insert({
        'user_id': userId,
        'action_type': 'opportunity_save',
        'reference_type': 'opportunity',
        'reference_id': opportunityId,
      });
    } else {
      await _client
          .from('saved_opportunities')
          .delete()
          .eq('opportunity_id', opportunityId)
          .eq('user_id', userId);
    }
  }

  Future<List<OpportunityModel>> getSavedOpportunities(String userId) async {
    final rows = await _client
        .from('saved_opportunities')
        .select('opportunity_id, opportunities(*)')
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    return (rows as List)
        .where((r) => r['opportunities'] != null)
        .map((r) => OpportunityModel.fromMap(r['opportunities'] as Map<String, dynamic>, isSaved: true))
        .toList();
  }

  Future<void> createOpportunity({
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
    await _client.from('opportunities').insert({
      'title': title,
      'organization': organization,
      'type': type.name,
      'description': description,
      'requirements': requirements,
      'location': location,
      'is_remote': isRemote,
      'application_url': applicationUrl,
      'deadline': deadline?.toIso8601String(),
      'posted_by': postedBy,
    });
  }
}
