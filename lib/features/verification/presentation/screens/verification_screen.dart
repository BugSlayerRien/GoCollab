import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/entities/verification_status.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/verification_providers.dart';

/// Member-facing verification. Most members never see this — signing up with
/// a school-domain email verifies them automatically. This is the fallback
/// for personal-Gmail accounts.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNumberController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _idDocument;

  @override
  void dispose() {
    _studentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    setState(() => _idDocument = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idDocument == null) {
      showActionFeedback(
        context,
        success: false,
        successMessage: '',
        errorMessage: 'Attach a photo of your school ID.',
      );
      return;
    }

    final error = await ref.read(verificationActionsControllerProvider.notifier).submit(
          studentNumber: _studentNumberController.text.trim(),
          idDocument: _idDocument!,
        );
    if (!mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'Submitted. An officer will review it shortly.',
      errorMessage: error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(effectiveVerificationStatusProvider);
    final requestAsync = ref.watch(myVerificationRequestProvider);
    final isSubmitting = ref.watch(verificationActionsControllerProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Account verification')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myVerificationRequestProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _StatusCard(status: status),
            const SizedBox(height: AppSpacing.lg),

            if (status == VerificationStatus.verified)
              Text(
                user?.studentNumber != null
                    ? 'Student number on file: ${user!.studentNumber}'
                    : 'Your school email confirmed your enrolment automatically — nothing else to do.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else if (status == VerificationStatus.pending)
              requestAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (request) => Text(
                  request == null
                      ? ''
                      : 'Submitted ${DateFormatter.date(request.submittedAt)}. '
                          'An officer will review your ID and you will be verified once approved.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              _SubmitForm(
                formKey: _formKey,
                studentNumberController: _studentNumberController,
                idDocument: _idDocument,
                isSubmitting: isSubmitting,
                previousRejectionReason: requestAsync.valueOrNull?.isRejected == true
                    ? requestAsync.valueOrNull?.rejectionReason
                    : null,
                onPickDocument: _pickDocument,
                onSubmit: _submit,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, message) = switch (status) {
      VerificationStatus.verified => (
          Icons.verified_rounded,
          'Your account is confirmed as a real student member. You can register for events and earn community points.',
        ),
      VerificationStatus.pending => (
          Icons.hourglass_top_rounded,
          'Your submission is waiting for an officer to review it.',
        ),
      VerificationStatus.rejected => (
          Icons.error_outline_rounded,
          'Your last submission was not accepted. You can correct the details and submit again below.',
        ),
      VerificationStatus.unverified => (
          Icons.shield_outlined,
          'You can browse GoCollab, but you need to be verified before you can register for events or earn points.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: context.appTextSecondary),
              const SizedBox(width: AppSpacing.sm),
              switch (status) {
                VerificationStatus.verified => StatusBadge.success(status.label),
                VerificationStatus.pending => StatusBadge.pending(status.label),
                VerificationStatus.rejected => StatusBadge.alert(status.label),
                VerificationStatus.unverified => StatusBadge.info(status.label),
              },
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SubmitForm extends StatelessWidget {
  const _SubmitForm({
    required this.formKey,
    required this.studentNumberController,
    required this.idDocument,
    required this.isSubmitting,
    required this.previousRejectionReason,
    required this.onPickDocument,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController studentNumberController;
  final XFile? idDocument;
  final bool isSubmitting;
  final String? previousRejectionReason;
  final VoidCallback onPickDocument;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previousRejectionReason != null && previousRejectionReason!.trim().isNotEmpty) ...[
            Text(
              'Officer note: ${previousRejectionReason!}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text('Submit proof of enrolment', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Only needed because your account email is not on your school domain. '
            'Your ID photo is stored privately and is visible only to chapter officers.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Student number',
            controller: studentNumberController,
            validator: (v) => Validators.required(v, fieldName: 'Student number'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('School ID photo', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          if (idDocument != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: FutureBuilder(
                  future: idDocument!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  },
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onPickDocument,
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: Text(idDocument == null ? 'Attach school ID' : 'Change photo'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Submit for review',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
