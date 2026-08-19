import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.sendPasswordResetOtp(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _emailSent = true);
      _startCooldown();
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.sendPasswordResetOtp(_emailController.text.trim());
    if (success && mounted) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new reset email has been sent.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authFormControllerProvider);

    ref.listen(authFormControllerProvider.select((s) => s.errorMessage), (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: AppColors.googleRed),
        );
      }
    });

    return AuthScaffold(
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(
              _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
              size: 48,
              color: AppColors.googleBlue,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _emailSent ? 'Check your inbox' : 'Reset your password',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _emailSent
                  ? 'We sent a password reset link to ${_emailController.text.trim()}. '
                    'Open the link in this same browser (same tab or a new tab). '
                    'The app will then ask you to set a new password.'
                  : "Enter the email associated with your account and we'll send you a reset link.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (!_emailSent) ...[
              AppTextField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
                validator: Validators.email,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Send reset link', isLoading: formState.isSubmitting, onPressed: _sendResetEmail),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.googleBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.googleBlue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.googleBlue, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'After clicking the link, you\'ll be brought back here to enter your new password.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.googleBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: _resendCooldown > 0 ? null : _resend,
                  child: Text(
                    _resendCooldown > 0 ? 'Resend email in ${_resendCooldown}s' : 'Resend email',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Back to sign in',
                variant: AppButtonVariant.outlined,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
