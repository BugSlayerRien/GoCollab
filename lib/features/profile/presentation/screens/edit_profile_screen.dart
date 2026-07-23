import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _programController;
  late final TextEditingController _yearController;
  late final TextEditingController _skillsController;
  late final TextEditingController _githubController;
  late final TextEditingController _linkedinController;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final editState = ref.watch(profileEditControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load profile.')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          if (!_initialized) {
            _nameController = TextEditingController(text: user.fullName);
            _bioController = TextEditingController(text: user.bio ?? '');
            _programController = TextEditingController(text: user.program ?? '');
            _yearController = TextEditingController(text: user.yearLevel ?? '');
            _skillsController = TextEditingController(text: user.skills.join(', '));
            _githubController = TextEditingController(text: user.githubUsername ?? '');
            _linkedinController = TextEditingController(text: user.linkedinUrl ?? '');
            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                AppTextField(label: 'Full name', controller: _nameController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Bio', controller: _bioController, maxLines: 3),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Program / Course', controller: _programController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: 'Year level', controller: _yearController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Skills (comma-separated)',
                  controller: _skillsController,
                  hint: 'Flutter, Dart, UI/UX Design',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'GitHub username',
                  controller: _githubController,
                  prefixIcon: Icons.code_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'LinkedIn URL',
                  controller: _linkedinController,
                  prefixIcon: Icons.link_rounded,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Save changes',
                  isLoading: editState.isLoading,
                  onPressed: () => _submit(user),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;
    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final updated = user.copyWith(
      fullName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      program: _programController.text.trim(),
      yearLevel: _yearController.text.trim(),
      skills: skills,
      githubUsername: _githubController.text.trim().isEmpty ? null : _githubController.text.trim(),
      linkedinUrl: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
    );

    final controller = ref.read(profileEditControllerProvider.notifier);
    final success = await controller.save(updated);

    if (success) {
      final githubUsername = updated.githubUsername;
      if (githubUsername != null) {
        await controller.syncGithub(userId: updated.id, username: githubUsername);
      }
      ref.invalidate(currentUserProvider);
      if (mounted) Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your profile. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _bioController.dispose();
      _programController.dispose();
      _yearController.dispose();
      _skillsController.dispose();
      _githubController.dispose();
      _linkedinController.dispose();
    }
    super.dispose();
  }
}
