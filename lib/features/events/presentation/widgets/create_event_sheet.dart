import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

void showEventEditorSheet(BuildContext context, {Event? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _EventEditorSheet(existing: existing),
  );
}

class _EventEditorSheet extends ConsumerStatefulWidget {
  const _EventEditorSheet({this.existing});
  final Event? existing;

  @override
  ConsumerState<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<_EventEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _onlineUrlController;
  late EventCategory _category;
  late EventStatus _status;
  late bool _isOnline;
  late DateTime _startAt;
  late DateTime _endAt;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _venueController = TextEditingController(text: existing?.venueName ?? '');
    _onlineUrlController = TextEditingController(text: existing?.onlineUrl ?? '');
    _category = existing?.category ?? EventCategory.workshop;
    _status = existing?.status ?? EventStatus.upcoming;
    _isOnline = existing?.isOnline ?? false;
    _startAt = existing?.startAt ?? DateTime.now().add(const Duration(days: 7, hours: 2));
    _endAt = existing?.endAt ?? _startAt.add(const Duration(hours: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _onlineUrlController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return DateTime(date.year, date.month, date.day, initial.hour, initial.minute);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endAt.isAfter(_startAt)) {
      showActionFeedback(
        context,
        success: false,
        successMessage: '',
        errorMessage: 'End time must be after the start time.',
      );
      return;
    }
    final controller = ref.read(eventActionsControllerProvider.notifier);
    final error = _isEditing
        ? await controller.updateEvent(
            id: widget.existing!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            startAt: _startAt,
            endAt: _endAt,
            venueName: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
            isOnline: _isOnline,
            onlineUrl: _onlineUrlController.text.trim().isEmpty ? null : _onlineUrlController.text.trim(),
            status: _status,
          )
        : await controller.createEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            startAt: _startAt,
            endAt: _endAt,
            venueName: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
            isOnline: _isOnline,
            onlineUrl: _onlineUrlController.text.trim().isEmpty ? null : _onlineUrlController.text.trim(),
          );
    if (!mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: _isEditing ? 'Event updated.' : 'Event created.',
      errorMessage: error,
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(eventActionsControllerProvider);
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
              Text(_isEditing ? 'Edit event' : 'New event', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xs,
                children: EventCategory.values.map((c) {
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
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
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                validator: (v) => Validators.required(v, fieldName: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Venue', controller: _venueController),
              CheckboxListTile(
                value: _isOnline,
                onChanged: (v) => setState(() => _isOnline = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Online event'),
              ),
              if (_isOnline)
                AppTextField(
                  label: 'Online URL',
                  controller: _onlineUrlController,
                  validator: Validators.url,
                ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<EventStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: EventStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Starts ${DateFormatter.dateTime(_startAt)}'),
                trailing: const Icon(Icons.schedule_rounded),
                onTap: () async {
                  final picked = await _pickDateTime(_startAt);
                  if (picked != null) setState(() => _startAt = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Ends ${DateFormatter.dateTime(_endAt)}'),
                trailing: const Icon(Icons.schedule_rounded),
                onTap: () async {
                  final picked = await _pickDateTime(_endAt);
                  if (picked != null) setState(() => _endAt = picked);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Create event',
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
