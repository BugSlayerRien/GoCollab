import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

enum _Step { email, otp, newPassword, done }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  _Step _step = _Step.email;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.sendPasswordResetOtp(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _step = _Step.otp);
      _startCooldown();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.sendPasswordResetOtp(_emailController.text.trim());
    if (success && mounted) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new OTP has been sent to your email.')),
      );
    }
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code.')),
      );
      return;
    }
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.verifyPasswordOtp(
      email: _emailController.text.trim(),
      token: otp,
    );
    if (success && mounted) {
      setState(() => _step = _Step.newPassword);
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.updatePassword(_passwordController.text);
    if (success && mounted) {
      setState(() => _step = _Step.done);
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
      showBackButton: _step != _Step.done,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(_stepIcon, size: 48, color: AppColors.googleBlue),
            const SizedBox(height: AppSpacing.lg),
            Text(_stepTitle, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _stepSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ..._stepContent(formState),
          ],
        ),
      ),
    );
  }

  IconData get _stepIcon => switch (_step) {
        _Step.email => Icons.lock_reset_rounded,
        _Step.otp => Icons.pin_rounded,
        _Step.newPassword => Icons.password_rounded,
        _Step.done => Icons.check_circle_outline_rounded,
      };

  String get _stepTitle => switch (_step) {
        _Step.email => 'Reset your password',
        _Step.otp => 'Enter verification code',
        _Step.newPassword => 'Create new password',
        _Step.done => 'Password updated',
      };

  String get _stepSubtitle => switch (_step) {
        _Step.email => "Enter the email associated with your account and we'll send you a verification code.",
        _Step.otp => 'We sent a 6-digit code to ${_emailController.text.trim()}. Enter it below.',
        _Step.newPassword => 'Choose a strong new password for your account.',
        _Step.done => 'Your password has been changed successfully. You can now sign in with your new password.',
      };

  List<Widget> _stepContent(AuthFormState formState) => switch (_step) {
        _Step.email => [
            AppTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: Validators.email,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Send verification code', isLoading: formState.isSubmitting, onPressed: _sendOtp),
          ],
        _Step.otp => [
            _OtpRow(
              controllers: _otpControllers,
              focusNodes: _otpFocusNodes,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Verify code', isLoading: formState.isSubmitting, onPressed: _verifyOtp),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _resendCooldown > 0 ? null : _resendOtp,
                child: Text(
                  _resendCooldown > 0 ? 'Resend code in ${_resendCooldown}s' : 'Resend code',
                ),
              ),
            ),
          ],
        _Step.newPassword => [
            AppTextField(
              label: 'New password',
              controller: _passwordController,
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirm password',
              controller: _confirmController,
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) => Validators.confirmPassword(v, _passwordController.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Update password', isLoading: formState.isSubmitting, onPressed: _updatePassword),
          ],
        _Step.done => [
            AppButton(
              label: 'Back to sign in',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
      };
}

class _OtpRow extends StatelessWidget {
  const _OtpRow({required this.controllers, required this.focusNodes});

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: 44,
          height: 56,
          margin: EdgeInsets.only(right: i < 5 ? AppSpacing.sm : 0),
          child: TextFormField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && i < 5) {
                focusNodes[i + 1].requestFocus();
              } else if (value.isEmpty && i > 0) {
                focusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
