import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/communication_log.dart';
import '../providers/partnership_providers.dart';

void showLogCommunicationSheet(
  BuildContext context, {
  required String partnerId,
  required String communicatedBy,
  CommunicationLog? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _LogCommunicationSheet(
      partnerId: partnerId,
      communicatedBy: communicatedBy,
      existing: existing,
    ),
  );
}

class _LogCommunicationSheet extends ConsumerStatefulWidget {
  const _LogCommunicationSheet({
    required this.partnerId,
    required this.communicatedBy,
    this.existing,
  });
  final String partnerId;
  final String communicatedBy;
  final CommunicationLog? existing;

  @override
  ConsumerState<_LogCommunicationSheet> createState() => _LogCommunicationSheetState();
}

class _LogCommunicationSheetState extends ConsumerState<_LogCommunicationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;
  late String _direction;
  late String _method;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.existing?.subject ?? '');
    _messageController = TextEditingController(text: widget.existing?.message ?? '');
    _direction = widget.existing?.direction ?? 'outbound';
    _method = widget.existing?.contactMethod ?? 'email';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
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
              Text(_isEditing ? 'Edit communication' : 'Log communication', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Subject',
                controller: _subjectController,
                validator: (v) => Validators.required(v, fieldName: 'Subject'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Notes', controller: _messageController, maxLines: 3),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _direction,
                      decoration: const InputDecoration(labelText: 'Direction'),
                      items: const ['outbound', 'inbound'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _direction = v ?? 'outbound'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(labelText: 'Method'),
                      items: const ['email', 'call', 'meeting', 'chat', 'other']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _method = v ?? 'email'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Save log',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final controller = ref.read(partnershipActionsControllerProvider.notifier);
                  final error = _isEditing
                      ? await controller.updateCommunication(
                          CommunicationLog(
                            id: widget.existing!.id,
                            partnerId: widget.partnerId,
                            subject: _subjectController.text.trim(),
                            direction: _direction,
                            contactMethod: _method,
                            communicatedAt: widget.existing!.communicatedAt,
                            message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
                            communicatedByName: widget.existing!.communicatedByName,
                          ),
                        )
                      : await controller.createCommunication(
                          partnerId: widget.partnerId,
                          subject: _subjectController.text.trim(),
                          message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
                          direction: _direction,
                          contactMethod: _method,
                          communicatedBy: widget.communicatedBy,
                        );
                  if (!context.mounted) return;
                  showActionFeedback(
                    context,
                    success: error == null,
                    successMessage: _isEditing ? 'Communication updated.' : 'Communication logged.',
                    errorMessage: error,
                  );
                  if (error == null) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
