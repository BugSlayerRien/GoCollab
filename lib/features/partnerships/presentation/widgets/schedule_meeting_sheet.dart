import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/meeting.dart';
import '../providers/partnership_providers.dart';

void showScheduleMeetingSheet(BuildContext context, {required String partnerId, Meeting? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ScheduleMeetingSheet(partnerId: partnerId, existing: existing),
  );
}

class _ScheduleMeetingSheet extends ConsumerStatefulWidget {
  const _ScheduleMeetingSheet({required this.partnerId, this.existing});
  final String partnerId;
  final Meeting? existing;

  @override
  ConsumerState<_ScheduleMeetingSheet> createState() => _ScheduleMeetingSheetState();
}

class _ScheduleMeetingSheetState extends ConsumerState<_ScheduleMeetingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _agendaController;
  late final TextEditingController _locationController;
  late DateTime _scheduledAt;
  late String _status;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _agendaController = TextEditingController(text: existing?.agenda ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _scheduledAt = existing?.scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    _status = existing?.status ?? 'scheduled';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _agendaController.dispose();
    _locationController.dispose();
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
              Text(_isEditing ? 'Edit meeting' : 'Schedule meeting', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Title',
                controller: _titleController,
                validator: (v) => Validators.required(v, fieldName: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Agenda', controller: _agendaController, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Location', controller: _locationController),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['scheduled', 'completed', 'cancelled', 'rescheduled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? 'scheduled'),
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date & time: ${_scheduledAt.toLocal()}'.split('.').first),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _scheduledAt,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                  );
                  if (time == null || !context.mounted) return;
                  setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Schedule',
                isLoading: isSubmitting,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final meeting = Meeting(
                    id: widget.existing?.id ?? '',
                    partnerId: widget.partnerId,
                    title: _titleController.text.trim(),
                    scheduledAt: _scheduledAt,
                    status: _status,
                    agenda: _agendaController.text.trim().isEmpty ? null : _agendaController.text.trim(),
                    location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                    notes: widget.existing?.notes,
                  );
                  final controller = ref.read(partnershipActionsControllerProvider.notifier);
                  final error = _isEditing ? await controller.updateMeeting(meeting) : await controller.createMeeting(meeting);
                  if (!context.mounted) return;
                  showActionFeedback(
                    context,
                    success: error == null,
                    successMessage: _isEditing ? 'Meeting updated.' : 'Meeting scheduled.',
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
