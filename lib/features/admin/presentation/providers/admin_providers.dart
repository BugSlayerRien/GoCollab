import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../../core/errors/exception_mapper.dart';

/// A member row for the admin "Members & roles" screen.
class AdminMember {
  const AdminMember({
    required this.id,
    required this.fullName,
    required this.email,
    required this.roleId,
    this.chapterId,
  });

  final String id;
  final String fullName;
  final String email;
  final int roleId;
  final String? chapterId;

  bool get isAdmin => roleId == 3;
  bool get isOfficer => roleId == 2;

  factory AdminMember.fromMap(Map<String, dynamic> m) => AdminMember(
        id: m['id'] as String,
        fullName: (m['full_name'] as String?) ?? '',
        email: (m['email'] as String?) ?? '',
        roleId: (m['role_id'] as num?)?.toInt() ?? 1,
        chapterId: m['chapter_id'] as String?,
      );
}

class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.actorName,
    this.targetType,
    this.detail = const {},
  });

  final String id;
  final String action;
  final DateTime createdAt;
  final String? actorName;
  final String? targetType;
  final Map<String, dynamic> detail;

  factory AuditEntry.fromMap(Map<String, dynamic> m) => AuditEntry(
        id: m['id'] as String,
        action: m['action'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        actorName: (m['actor'] as Map?)?['full_name'] as String?,
        targetType: m['target_type'] as String?,
        detail: (m['detail'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

/// Search text for the members screen.
final adminMemberQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final adminMembersProvider = FutureProvider.autoDispose<List<AdminMember>>((ref) async {
  final query = ref.watch(adminMemberQueryProvider).trim();
  var request = ref.watch(supabaseClientProvider).from('profiles').select('id, full_name, email, role_id, chapter_id');
  if (query.isNotEmpty) {
    final safe = query.replaceAll(RegExp(r'[,()%]'), ' ');
    request = request.or('full_name.ilike.%$safe%,email.ilike.%$safe%');
  }
  final rows = await request.order('full_name').limit(60);
  return (rows as List).map((r) => AdminMember.fromMap(r as Map<String, dynamic>)).toList();
});

/// Newest first. RLS limits an officer to their own chapter's entries and
/// lets an admin see everything.
final auditLogProvider = FutureProvider.autoDispose<List<AuditEntry>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('audit_log')
      .select('id, action, target_type, detail, created_at, actor:profiles(full_name)')
      .order('created_at', ascending: false)
      .limit(150);
  return (rows as List).map((r) => AuditEntry.fromMap(r as Map<String, dynamic>)).toList();
});

class AdminActions extends StateNotifier<bool> {
  AdminActions(this._ref) : super(false);
  final Ref _ref;

  Future<String?> _run(Future<void> Function() body) async {
    state = true;
    try {
      await body();
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }

  Future<String?> setRole(String userId, int roleId) => _run(() async {
        await _ref.read(supabaseClientProvider).rpc('set_member_role', params: {'p_user': userId, 'p_role': roleId});
        _ref.invalidate(adminMembersProvider);
        _ref.invalidate(auditLogProvider);
      });

  Future<String?> assignChapter(String userId, String chapterId) => _run(() async {
        await _ref
            .read(supabaseClientProvider)
            .rpc('assign_member_chapter', params: {'p_user': userId, 'p_chapter': chapterId});
        _ref.invalidate(adminMembersProvider);
        _ref.invalidate(auditLogProvider);
      });

  Future<String?> createChapter({required String name, required String campus, String? region}) => _run(() async {
        await _ref.read(supabaseClientProvider).from('chapters').insert({
          'name': name,
          'campus': campus,
          if (region != null && region.isNotEmpty) 'region': region,
        });
        _ref.invalidate(auditLogProvider);
      });

  Future<String?> setChapterActive(String id, bool active) => _run(() async {
        await _ref.read(supabaseClientProvider).from('chapters').update({'is_active': active}).eq('id', id);
        _ref.invalidate(auditLogProvider);
      });

  Future<String?> deleteChapter(String id) => _run(() async {
        await _ref.read(supabaseClientProvider).from('chapters').delete().eq('id', id);
        _ref.invalidate(auditLogProvider);
      });
}

final adminActionsProvider = StateNotifierProvider<AdminActions, bool>((ref) => AdminActions(ref));
