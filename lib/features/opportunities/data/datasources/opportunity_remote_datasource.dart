import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/entities/opportunity_applicant.dart';
import '../models/opportunity_model.dart';

class OpportunityRemoteDataSource {
  OpportunityRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _opportunitySelect =
      '*, creator:profiles!opportunities_posted_by_fkey(id, full_name, avatar_url)';

  static const _applicantSelect =
      'user_id, note, applied_at, applicant:profiles!opportunity_applications_user_id_fkey(id, full_name, avatar_url)';

  /// Own application rows for the given user, keyed by opportunity_id. RLS
  /// already restricts `opportunity_applications` to the caller's own rows
  /// (or all rows for officers), so this is safe to call unfiltered by role.
  Future<Map<String, Map<String, dynamic>>> _myApplicationsByOpportunity(String userId) async {
    final rows = await _client
        .from('opportunity_applications')
        .select('opportunity_id, note, applied_at')
        .eq('user_id', userId);
    return {
      for (final r in rows as List) (r as Map<String, dynamic>)['opportunity_id'] as String: r,
    };
  }

  Future<List<OpportunityModel>> getOpportunities({String? currentUserId}) async {
    final rows = await _client.from('opportunities').select(_opportunitySelect).order('deadline');

    Set<String> savedIds = {};
    Map<String, Map<String, dynamic>> myApplications = {};
    if (currentUserId != null) {
      final savedRows =
          await _client.from('saved_opportunities').select('opportunity_id').eq('user_id', currentUserId);
      savedIds = (savedRows as List).map((r) => r['opportunity_id'] as String).toSet();
      myApplications = await _myApplicationsByOpportunity(currentUserId);
    }

    return (rows as List)
        .map((row) => OpportunityModel.fromMap(
              row as Map<String, dynamic>,
              isSaved: savedIds.contains(row['id']),
              myApplication: myApplications[row['id']],
            ))
        .toList();
  }

  Future<OpportunityModel> getOpportunityById(String id, {String? currentUserId}) async {
    final row = await _client.from('opportunities').select(_opportunitySelect).eq('id', id).single();

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

    // RLS returns only the caller's own row for members, or every row for
    // officers — so this single query doubles as "did I apply?" and "who
    // applied?" depending on who's asking.
    final applicationRows =
        await _client.from('opportunity_applications').select(_applicantSelect).eq('opportunity_id', id).order(
              'applied_at',
              ascending: false,
            );

    Map<String, dynamic>? myApplication;
    final applicants = <OpportunityApplicant>[];
    for (final r in applicationRows as List) {
      final map = r as Map<String, dynamic>;
      applicants.add(OpportunityApplicantModel.fromMap(map));
      if (currentUserId != null && map['user_id'] == currentUserId) {
        myApplication = map;
      }
    }

    return OpportunityModel.fromMap(row, isSaved: isSaved, myApplication: myApplication, applicants: applicants);
  }

  Future<void> markApplied({required String opportunityId, required String userId, String? note}) async {
    await _client.from('opportunity_applications').upsert({
      'opportunity_id': opportunityId,
      'user_id': userId,
      'note': note,
      'applied_at': DateTime.now().toIso8601String(),
    }, onConflict: 'opportunity_id,user_id');

    try {
      await _client.from('engagement_logs').insert({
        'user_id': userId,
        'action_type': 'opportunity_apply',
        'reference_type': 'opportunity',
        'reference_id': opportunityId,
      });
    } catch (_) {
      // Application record is already persisted; points/analytics must not roll it back.
    }
  }

  Future<List<OpportunityModel>> getAppliedOpportunities(String userId) async {
    final rows = await _client
        .from('opportunity_applications')
        .select('opportunity_id, note, applied_at, opportunities($_opportunitySelect)')
        .eq('user_id', userId)
        .order('applied_at', ascending: false);

    final savedRows = await _client.from('saved_opportunities').select('opportunity_id').eq('user_id', userId);
    final savedIds = (savedRows as List).map((r) => r['opportunity_id'] as String).toSet();

    return (rows as List)
        .where((r) => r['opportunities'] != null)
        .map((r) {
          final map = r as Map<String, dynamic>;
          return OpportunityModel.fromMap(
            map['opportunities'] as Map<String, dynamic>,
            isSaved: savedIds.contains(map['opportunity_id']),
            myApplication: map,
          );
        })
        .toList();
  }

  Future<void> toggleSaved({required String opportunityId, required String userId, required bool save}) async {
    if (save) {
      await _client.from('saved_opportunities').upsert(
        {'opportunity_id': opportunityId, 'user_id': userId},
        onConflict: 'user_id,opportunity_id',
      );
      try {
        await _client.from('engagement_logs').insert({
          'user_id': userId,
          'action_type': 'opportunity_save',
          'reference_type': 'opportunity',
          'reference_id': opportunityId,
        });
      } catch (_) {
        // Bookmark is already persisted; analytics must not roll it back.
      }
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
        .select('opportunity_id, opportunities($_opportunitySelect)')
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

  Future<void> updateOpportunity({
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
    await _client.from('opportunities').update({
      'title': title,
      'organization': organization,
      'type': type.name,
      'description': description,
      'requirements': requirements,
      'location': location,
      'is_remote': isRemote,
      'application_url': applicationUrl,
      'deadline': deadline?.toIso8601String(),
      'status': status,
    }).eq('id', id);
  }

  Future<void> deleteOpportunity(String id) async {
    await _client.from('opportunities').delete().eq('id', id);
  }
}
