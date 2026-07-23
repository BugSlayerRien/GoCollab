import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../announcements/domain/entities/announcement.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';

void showCreateAnnouncementSheet(BuildContext context, WidgetRef ref, {required String authorId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CreateAnnouncementSheet(authorId: authorId),
  );
}

class _CreateAnnouncementSheet extends ConsumerStatefulWidget {
  const _CreateAnnouncementSheet({required this.authorId});
  final String authorId;

  @override
  ConsumerState<_CreateAnnouncementSheet> createState() => _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends ConsumerState<_CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  AnnouncementCategory _category = AnnouncementCategory.general;
  bool _pinned = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(announcementControllerProvider.notifier);
    final success = await controller.create(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      category: _category,
      isPinned: _pinned,
      createdBy: widget.authorId,
    );
    if (success && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(announcementControllerProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New announcement', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Title',
                controller: _titleController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Message',
                controller: _bodyController,
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty ? 'Message is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                children: AnnouncementCategory.values.map((c) {
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              CheckboxListTile(
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Pin to top'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Publish', isLoading: isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
