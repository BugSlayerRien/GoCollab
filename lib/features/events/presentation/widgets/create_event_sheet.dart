import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/place_search_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sheet_messenger.dart';
import '../../../partnerships/domain/entities/partner.dart';
import '../../../partnerships/presentation/providers/partnership_providers.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

void showEventEditorSheet(BuildContext context, {Event? existing}) {
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => SheetMessenger(child: _EventEditorSheet(existing: existing, messenger: messenger)),
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
  final _placeSearchService = PlaceSearchService();
  final _placeSearchController = TextEditingController();
  Timer? _placeSearchDebounce;
  List<PlaceSuggestion> _placeSuggestions = [];
  bool _placeSearching = false;
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
  String? _partnerId;

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
    _partnerId = existing?.partnerId;
  }

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _placeSearchController.dispose();
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

  void _onPlaceSearchChanged(String query) {
    _placeSearchDebounce?.cancel();
    if (query.trim().length < 3) {
      setState(() {
        _placeSuggestions = [];
        _placeSearching = false;
      });
      return;
    }
    setState(() => _placeSearching = true);
    _placeSearchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _placeSearchService.search(query);
      if (!mounted) return;
      setState(() {
        _placeSuggestions = results;
        _placeSearching = false;
      });
    });
  }

  void _selectPlace(PlaceSuggestion place) {
    setState(() {
      _venueAddressController.text = place.displayName;
      _latitudeController.text = place.latitude.toString();
      _longitudeController.text = place.longitude.toString();
      _placeSuggestions = [];
      _placeSearchController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _addPartnerInline() async {
    final nameController = TextEditingController();
    var category = PartnerCategory.industry;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('New partner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Organization name'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<PartnerCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: PartnerCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => category = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: nameController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (created != true || !mounted) return;

    String? error;
    final id = await ref.read(partnershipActionsControllerProvider.notifier).createPartnerMinimal(
          name: nameController.text.trim(),
          category: category,
          onError: (message) => error = message,
        );
    if (!mounted) return;
    if (id == null) {
      showActionFeedback(
        context,
        success: false,
        successMessage: '',
        errorMessage: error ?? 'Could not add partner.',
      );
      return;
    }
    setState(() => _partnerId = id);
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
        success: false,
        successMessage: '',
        errorMessage: coordinateError,
      );
      return;
    }

    if (!_endAt.isAfter(_startAt)) {
      showActionFeedback(
        context,
        success: false,
        successMessage: '',
        errorMessage: 'End time must be after the start time.',
      );
      return;
    }

    if (_registrationDeadline != null && !_registrationDeadline!.isBefore(_startAt)) {
      showActionFeedback(
        context,
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
            partnerId: _partnerId,
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
            partnerId: _partnerId,
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
              AppTextField(
                label: _isOnline ? 'Venue name (optional)' : 'Venue name',
                controller: _venueController,
                validator: (v) =>
                    _isOnline ? null : Validators.required(v, fieldName: 'Venue name'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Search for a place',
                hint: 'Type a venue or address, e.g. "SM City Baliwag"',
                controller: _placeSearchController,
                prefixIcon: Icons.search_rounded,
                onChanged: _onPlaceSearchChanged,
              ),
              if (_placeSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: LinearProgressIndicator(),
                ),
              if (_placeSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.appBorder),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _placeSuggestions
                        .map((place) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(place.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () => _selectPlace(place),
                            ))
                        .toList(),
                  ),
                ),
              Text(
                'Powered by OpenStreetMap. Pick a result to auto-fill the address and coordinates below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Venue address (optional)',
                controller: _venueAddressController,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: _latitudeController.text.isNotEmpty,
                title: Text('Fine-tune coordinates', style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text(
                  'Auto-filled by search above — edit manually only if needed.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                ),
                children: [
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
                  const SizedBox(height: AppSpacing.sm),
                ],
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
                  validator: (v) => Validators.requiredUrl(v, fieldName: 'Online URL'),
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
              Text('Partner / sponsor (optional)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Consumer(
                builder: (context, ref, _) {
                  final partnersAsync = ref.watch(partnersListProvider);
                  return partnersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => Text(
                      'Could not load partners.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                    ),
                    data: (partners) {
                      final hasCurrent = partners.any((p) => p.id == _partnerId);
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: hasCurrent ? _partnerId : null,
                              decoration: const InputDecoration(labelText: 'Partner'),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                                ...partners.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name))),
                              ],
                              onChanged: (value) => setState(() => _partnerId = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: _addPartnerInline,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New'),
                          ),
                        ],
                      );
                    },
                  );
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
