import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/partner.dart';
import '../providers/partnership_providers.dart';

void showPartnerEditorSheet(BuildContext context, {Partner? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PartnerEditorSheet(existing: existing),
  );
}

void showCreatePartnerSheet(BuildContext context) {
  showPartnerEditorSheet(context);
}

class _PartnerEditorSheet extends ConsumerStatefulWidget {
  const _PartnerEditorSheet({this.existing});
  final Partner? existing;

  @override
  ConsumerState<_PartnerEditorSheet> createState() => _PartnerEditorSheetState();
}

class _PartnerEditorSheetState extends ConsumerState<_PartnerEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactPersonController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late PartnerCategory _category;
  late CollaborationStatus _status;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _contactPersonController = TextEditingController(text: existing?.contactPerson ?? '');
    _contactEmailController = TextEditingController(text: existing?.contactEmail ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _websiteController = TextEditingController(text: existing?.website ?? '');
    _category = existing?.category ?? PartnerCategory.industry;
    _status = existing?.collaborationStatus ?? CollaborationStatus.prospect;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contactPersonController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final partner = Partner(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      category: _category,
      collaborationStatus: _status,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      latitude: widget.existing?.latitude,
      longitude: widget.existing?.longitude,
      contactPhone: widget.existing?.contactPhone,
      logoUrl: widget.existing?.logoUrl,
    );
    final controller = ref.read(partnershipActionsControllerProvider.notifier);
    final error = _isEditing ? await controller.updatePartner(partner) : await controller.createPartner(partner);
    if (!mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: _isEditing ? 'Partner updated.' : 'Partner added.',
      errorMessage: error,
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(partnershipActionsControllerProvider);
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
              Text(_isEditing ? 'Edit partner' : 'New partner', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xs,
                children: PartnerCategory.values.map((c) {
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Organization name',
                controller: _nameController,
                validator: (v) => Validators.required(v, fieldName: 'Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Description', controller: _descriptionController, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Contact person', controller: _contactPersonController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Contact email',
                controller: _contactEmailController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return Validators.email(v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Address', controller: _addressController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Website', controller: _websiteController, validator: Validators.url),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<CollaborationStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Collaboration status'),
                  items: CollaborationStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Add partner',
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
