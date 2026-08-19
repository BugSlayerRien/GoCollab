import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';
import '../../../../core/services/supabase_service.dart';

/// Shown after the user clicks the password-reset magic link from their email.
/// At this point Supabase has already established a recovery session, so the
/// user only needs to enter their new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authFormControllerProvider.notifier);
    final success = await controller.updatePassword(_passwordController.text);
    if (success && mounted) {
      ref.read(isPasswordRecoveryProvider.notifier).state = false;
      SupabaseService.pendingPasswordRecovery = false;
      await ref.read(signOutUseCaseProvider)();
      setState(() => _done = true);
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Icon(
              _done ? Icons.check_circle_outline_rounded : Icons.password_rounded,
              size: 48,
              color: _done ? AppColors.googleGreen : AppColors.googleBlue,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _done ? 'Password updated' : 'Create new password',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _done
                  ? 'Your password has been changed successfully. You can now sign in with your new password.'
                  : 'Choose a strong new password for your account.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (!_done) ...[
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
              AppButton(label: 'Update password', isLoading: formState.isSubmitting, onPressed: _submit),
            ] else
              AppButton(
                label: 'Back to sign in',
                onPressed: () => context.go('/login'),
              ),
          ],
        ),
      ),
    );
  }
}
