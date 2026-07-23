import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/partner.dart';
import '../providers/partnership_providers.dart';

void showCreatePartnerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _CreatePartnerSheet(),
  );
}

class _CreatePartnerSheet extends ConsumerStatefulWidget {
  const _CreatePartnerSheet();

  @override
  ConsumerState<_CreatePartnerSheet> createState() => _CreatePartnerSheetState();
}

class _CreatePartnerSheetState extends ConsumerState<_CreatePartnerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  PartnerCategory _category = PartnerCategory.industry;

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
      id: '',
      name: _nameController.text.trim(),
      category: _category,
      collaborationStatus: CollaborationStatus.prospect,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
    );
    final success = await ref.read(partnershipActionsControllerProvider.notifier).createPartner(partner);
    if (success && context.mounted) Navigator.of(context).pop();
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
              Text('New partner', style: Theme.of(context).textTheme.titleLarge),
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
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Description', controller: _descriptionController, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Contact person', controller: _contactPersonController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Contact email', controller: _contactEmailController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Address', controller: _addressController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Website', controller: _websiteController),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Add partner', isLoading: isSubmitting, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
