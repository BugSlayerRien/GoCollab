import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';

/// A GoCollab chapter (campus) from `public.chapters`.
class ChapterOption {
  const ChapterOption({required this.id, required this.name, required this.campus, this.isActive = true});

  final String id;
  final String name;
  final String campus;
  final bool isActive;

  factory ChapterOption.fromMap(Map<String, dynamic> map) => ChapterOption(
        id: map['id'] as String,
        name: map['name'] as String,
        campus: (map['campus'] as String?) ?? '',
        isActive: map['is_active'] as bool? ?? true,
      );
}

/// Every chapter, active first. Readable by any signed-in user.
final chapterOptionsProvider = FutureProvider.autoDispose<List<ChapterOption>>((ref) async {
  final rows = await ref
      .watch(supabaseClientProvider)
      .from('chapters')
      .select('id, name, campus, is_active')
      .order('name');
  return (rows as List).map((r) => ChapterOption.fromMap(r as Map<String, dynamic>)).toList();
});
