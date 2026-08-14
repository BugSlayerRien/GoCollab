import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../announcements/domain/entities/announcement.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';

void showAnnouncementEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  required String authorId,
  Announcement? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AnnouncementEditorSheet(authorId: authorId, existing: existing),
  );
}

void showCreateAnnouncementSheet(BuildContext context, WidgetRef ref, {required String authorId}) {
  showAnnouncementEditorSheet(context, ref, authorId: authorId);
}

class _AnnouncementEditorSheet extends ConsumerStatefulWidget {
  const _AnnouncementEditorSheet({required this.authorId, this.existing});
  final String authorId;
  final Announcement? existing;

  @override
  ConsumerState<_AnnouncementEditorSheet> createState() => _AnnouncementEditorSheetState();
}

class _AnnouncementEditorSheetState extends ConsumerState<_AnnouncementEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late AnnouncementCategory _category;
  late bool _pinned;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _bodyController = TextEditingController(text: widget.existing?.body ?? '');
    _category = widget.existing?.category ?? AnnouncementCategory.general;
    _pinned = widget.existing?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(announcementControllerProvider.notifier);
    final error = _isEditing
        ? await controller.update(
            id: widget.existing!.id,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            category: _category,
            isPinned: _pinned,
          )
        : await controller.create(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            category: _category,
            isPinned: _pinned,
            createdBy: widget.authorId,
          );
    if (!mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: _isEditing ? 'Announcement updated.' : 'Announcement published.',
      errorMessage: error,
    );
    if (error == null) Navigator.of(context).pop();
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
              Text(_isEditing ? 'Edit announcement' : 'New announcement', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Title',
                controller: _titleController,
                validator: (v) => Validators.required(v, fieldName: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Message',
                controller: _bodyController,
                maxLines: 4,
                validator: (v) => Validators.required(v, fieldName: 'Message'),
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
              AppButton(label: _isEditing ? 'Save changes' : 'Publish', isLoading: isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
