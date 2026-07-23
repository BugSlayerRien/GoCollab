import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunity_providers.dart';

void showCreateOpportunitySheet(BuildContext context, {required String postedBy}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CreateOpportunitySheet(postedBy: postedBy),
  );
}

class _CreateOpportunitySheet extends ConsumerStatefulWidget {
  const _CreateOpportunitySheet({required this.postedBy});
  final String postedBy;

  @override
  ConsumerState<_CreateOpportunitySheet> createState() => _CreateOpportunitySheetState();
}

class _CreateOpportunitySheetState extends ConsumerState<_CreateOpportunitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _orgController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _urlController = TextEditingController();
  OpportunityType _type = OpportunityType.internship;
  bool _isRemote = false;
  DateTime? _deadline;

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
    final success = await controller.create(
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
    if (success && context.mounted) Navigator.of(context).pop();
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New opportunity', style: Theme.of(context).textTheme.titleLarge),
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
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Organization',
                controller: _orgController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Organization is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Description', controller: _descriptionController, maxLines: 3),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Requirements', controller: _requirementsController, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Location', controller: _locationController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Application URL', controller: _urlController),
              CheckboxListTile(
                value: _isRemote,
                onChanged: (v) => setState(() => _isRemote = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Remote-friendly'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_deadline == null ? 'No deadline set' : 'Deadline: ${_deadline!.toLocal()}'.split('.').first),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Publish opportunity', isLoading: isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
