import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunity_providers.dart';

void showOpportunityEditorSheet(
  BuildContext context, {
  required String postedBy,
  Opportunity? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _OpportunityEditorSheet(postedBy: postedBy, existing: existing),
  );
}

/// Backwards-compatible alias used by the Career Hub FAB.
void showCreateOpportunitySheet(BuildContext context, {required String postedBy}) {
  showOpportunityEditorSheet(context, postedBy: postedBy);
}

class _OpportunityEditorSheet extends ConsumerStatefulWidget {
  const _OpportunityEditorSheet({required this.postedBy, this.existing});
  final String postedBy;
  final Opportunity? existing;

  @override
  ConsumerState<_OpportunityEditorSheet> createState() => _OpportunityEditorSheetState();
}

class _OpportunityEditorSheetState extends ConsumerState<_OpportunityEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _orgController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _requirementsController;
  late final TextEditingController _locationController;
  late final TextEditingController _urlController;
  late OpportunityType _type;
  late bool _isRemote;
  late String _status;
  DateTime? _deadline;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _orgController = TextEditingController(text: existing?.organization ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _requirementsController = TextEditingController(text: existing?.requirements ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _urlController = TextEditingController(text: existing?.applicationUrl ?? '');
    _type = existing?.type ?? OpportunityType.internship;
    _isRemote = existing?.isRemote ?? false;
    _status = existing?.status ?? 'open';
    _deadline = existing?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orgController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(createOpportunityControllerProvider.notifier);
    final error = _isEditing
        ? await controller.update(
            id: widget.existing!.id,
            title: _titleController.text.trim(),
            organization: _orgController.text.trim(),
            type: _type,
            description: _descriptionController.text.trim(),
            requirements: _requirementsController.text.trim().isEmpty ? null : _requirementsController.text.trim(),
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            isRemote: _isRemote,
            applicationUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
            deadline: _deadline,
            status: _status,
          )
        : await controller.create(
            title: _titleController.text.trim(),
            organization: _orgController.text.trim(),
            type: _type,
            description: _descriptionController.text.trim(),
            requirements: _requirementsController.text.trim().isEmpty ? null : _requirementsController.text.trim(),
            location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
            isRemote: _isRemote,
            applicationUrl: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
            deadline: _deadline,
            postedBy: widget.postedBy,
          );
    if (!mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: _isEditing ? 'Opportunity updated.' : 'Opportunity published.',
      errorMessage: error,
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(createOpportunityControllerProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isEditing ? 'Edit opportunity' : 'New opportunity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xs,
                children: OpportunityType.values.map((t) {
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Title',
                controller: _titleController,
                validator: (v) => Validators.required(v, fieldName: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Organization',
                controller: _orgController,
                validator: (v) => Validators.required(v, fieldName: 'Organization'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                validator: (v) => Validators.required(v, fieldName: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Requirements', controller: _requirementsController, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: _isRemote ? 'Location (optional)' : 'Location',
                controller: _locationController,
                validator: (v) => _isRemote ? null : Validators.required(v, fieldName: 'Location'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Application URL',
                controller: _urlController,
                validator: (v) => Validators.requiredUrl(v, fieldName: 'Application URL'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
              CheckboxListTile(
                value: _isRemote,
                onChanged: (v) => setState(() => _isRemote = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Remote-friendly'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _deadline == null ? 'No deadline set' : 'Deadline: ${_deadline!.toLocal()}'.split('.').first,
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Publish opportunity',
                isLoading: isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
