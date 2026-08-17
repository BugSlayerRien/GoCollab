import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

void showEventEditorSheet(BuildContext context, {Event? existing}) {
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _EventEditorSheet(existing: existing, messenger: messenger),
  );
}

class _EventEditorSheet extends ConsumerStatefulWidget {
  const _EventEditorSheet({required this.messenger, this.existing});
  final ScaffoldMessengerState messenger;
  final Event? existing;

  @override
  ConsumerState<_EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<_EventEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _venueController;
  late final TextEditingController _venueAddressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _capacityController;
  late final TextEditingController _onlineUrlController;
  late EventCategory _category;
  late EventStatus _status;
  late bool _isOnline;
  late DateTime _startAt;
  late DateTime _endAt;
  DateTime? _registrationDeadline;
  XFile? _bannerFile;
  bool _removeBanner = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _venueController = TextEditingController(text: existing?.venueName ?? '');
    _venueAddressController = TextEditingController(text: existing?.venueAddress ?? '');
    _latitudeController = TextEditingController(
      text: existing?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: existing?.longitude?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: existing?.capacity?.toString() ?? '',
    );
    _onlineUrlController = TextEditingController(text: existing?.onlineUrl ?? '');
    _category = existing?.category ?? EventCategory.workshop;
    _status = existing?.status ?? EventStatus.upcoming;
    _isOnline = existing?.isOnline ?? false;
    _startAt = existing?.startAt ?? DateTime.now().add(const Duration(days: 7, hours: 2));
    _endAt = existing?.endAt ?? _startAt.add(const Duration(hours: 3));
    _registrationDeadline = existing?.registrationDeadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _venueAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _capacityController.dispose();
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

  Future<void> _pickBanner() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _bannerFile = file;
      _removeBanner = false;
    });
  }

  double? _parseOptionalDouble(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  int? _parseOptionalInt(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  String? _validateCoordinates() {
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();
    if (latText.isEmpty && lngText.isEmpty) return null;
    if (latText.isEmpty || lngText.isEmpty) {
      return 'Enter both latitude and longitude to show the venue map.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showActionFeedback(
        context,
        messenger: widget.messenger,
        success: false,
        successMessage: '',
        errorMessage: 'Please fix the highlighted fields before saving.',
      );
      return;
    }

    final coordinateError = _validateCoordinates();
    if (coordinateError != null) {
      showActionFeedback(
        context,
        messenger: widget.messenger,
        success: false,
        successMessage: '',
        errorMessage: coordinateError,
      );
      return;
    }

    if (!_endAt.isAfter(_startAt)) {
      showActionFeedback(
        context,
        messenger: widget.messenger,
        success: false,
        successMessage: '',
        errorMessage: 'End time must be after the start time.',
      );
      return;
    }

    if (_registrationDeadline != null && !_registrationDeadline!.isBefore(_startAt)) {
      showActionFeedback(
        context,
        messenger: widget.messenger,
        success: false,
        successMessage: '',
        errorMessage: 'Registration deadline must be before the event starts.',
      );
      return;
    }

    final controller = ref.read(eventActionsControllerProvider.notifier);
    final venueName = _venueController.text.trim().isEmpty ? null : _venueController.text.trim();
    final venueAddress = _venueAddressController.text.trim().isEmpty ? null : _venueAddressController.text.trim();
    final latitude = _parseOptionalDouble(_latitudeController.text);
    final longitude = _parseOptionalDouble(_longitudeController.text);
    final capacity = _parseOptionalInt(_capacityController.text);

    final resultMessage = _isEditing
        ? await controller.updateEvent(
            id: widget.existing!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            startAt: _startAt,
            endAt: _endAt,
            venueName: venueName,
            venueAddress: venueAddress,
            latitude: latitude,
            longitude: longitude,
            isOnline: _isOnline,
            onlineUrl: _onlineUrlController.text.trim().isEmpty ? null : _onlineUrlController.text.trim(),
            capacity: capacity,
            registrationDeadline: _registrationDeadline,
            status: _status,
            existingBannerUrl: widget.existing!.bannerUrl,
            bannerFile: _bannerFile,
            removeBanner: _removeBanner,
          )
        : await controller.createEvent(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _category,
            startAt: _startAt,
            endAt: _endAt,
            venueName: venueName,
            venueAddress: venueAddress,
            latitude: latitude,
            longitude: longitude,
            isOnline: _isOnline,
            onlineUrl: _onlineUrlController.text.trim().isEmpty ? null : _onlineUrlController.text.trim(),
            capacity: capacity,
            registrationDeadline: _registrationDeadline,
            bannerFile: _bannerFile,
          );

    if (!mounted) return;

    if (resultMessage == null) {
      Navigator.of(context).pop();
      showActionFeedback(
        context,
        messenger: widget.messenger,
        success: true,
        successMessage: _isEditing ? 'Event updated.' : 'Event created.',
      );
      return;
    }

    if (resultMessage.startsWith('__saved__')) {
      Navigator.of(context).pop();
      showActionFeedback(
        context,
        messenger: widget.messenger,
        success: false,
        successMessage: '',
        errorMessage: resultMessage.substring('__saved__'.length),
        isWarning: true,
      );
      return;
    }

    showActionFeedback(
      context,
      messenger: widget.messenger,
      success: false,
      successMessage: '',
      errorMessage: resultMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(eventActionsControllerProvider);
    final existingBanner = widget.existing?.bannerUrl;
    final showExistingBanner = existingBanner != null && !_removeBanner && _bannerFile == null;

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
              Text('Banner image', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              if (_bannerFile != null || showExistingBanner)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _bannerFile != null
                        ? FutureBuilder(
                            future: _bannerFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            },
                          )
                        : Image.network(existingBanner!, fit: BoxFit.cover),
                  ),
                ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickBanner,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(showExistingBanner || _bannerFile != null ? 'Change banner' : 'Add banner'),
                  ),
                  if (showExistingBanner || _bannerFile != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _bannerFile = null;
                        _removeBanner = true;
                      }),
                      child: const Text('Remove'),
                    ),
                ],
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
              AppTextField(
                label: 'Capacity (optional)',
                controller: _capacityController,
                keyboardType: TextInputType.number,
                validator: (v) => Validators.optionalPositiveInt(v, fieldName: 'Capacity'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: 'Venue name', controller: _venueController),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Venue address (optional)',
                controller: _venueAddressController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (v) => Validators.optionalCoordinate(v, isLatitude: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (v) => Validators.optionalCoordinate(v, isLatitude: false),
                    ),
                  ),
                ],
              ),
              Text(
                'Add coordinates to show the venue map (copy from Google Maps).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  value: _isOnline,
                  onChanged: (v) => setState(() => _isOnline = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Online event'),
                ),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _registrationDeadline == null
                      ? 'Registration deadline (optional)'
                      : 'Registration closes ${DateFormatter.dateTime(_registrationDeadline!)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_registrationDeadline != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _registrationDeadline = null),
                      ),
                    const Icon(Icons.event_busy_outlined),
                  ],
                ),
                onTap: () async {
                  final picked = await _pickDateTime(_registrationDeadline ?? _startAt.subtract(const Duration(days: 1)));
                  if (picked != null) setState(() => _registrationDeadline = picked);
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
