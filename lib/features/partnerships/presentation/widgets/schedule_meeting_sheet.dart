import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/meeting.dart';
import '../providers/partnership_providers.dart';

void showScheduleMeetingSheet(BuildContext context, {required String partnerId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ScheduleMeetingSheet(partnerId: partnerId),
  );
}

class _ScheduleMeetingSheet extends ConsumerStatefulWidget {
  const _ScheduleMeetingSheet({required this.partnerId});
  final String partnerId;

  @override
  ConsumerState<_ScheduleMeetingSheet> createState() => _ScheduleMeetingSheetState();
}

class _ScheduleMeetingSheetState extends ConsumerState<_ScheduleMeetingSheet> {
  final _titleController = TextEditingController();
  final _agendaController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Schedule meeting', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Title', controller: _titleController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Agenda', controller: _agendaController, maxLines: 2),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Location', controller: _locationController),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date & time: ${_scheduledAt.toLocal()}'.split('.').first),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledAt));
                if (time == null) return;
                setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Schedule',
              isLoading: isSubmitting,
              onPressed: () async {
                if (_titleController.text.trim().isEmpty) return;
                final success = await ref.read(partnershipActionsControllerProvider.notifier).createMeeting(
                      Meeting(
                        id: '',
                        partnerId: widget.partnerId,
                        title: _titleController.text.trim(),
                        scheduledAt: _scheduledAt,
                        status: 'scheduled',
                        agenda: _agendaController.text.trim().isEmpty ? null : _agendaController.text.trim(),
                        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
                      ),
                    );
                if (success && context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
