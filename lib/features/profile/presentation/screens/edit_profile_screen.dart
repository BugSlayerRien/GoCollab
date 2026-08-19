import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
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
                _AvatarPicker(user: user),
                const SizedBox(height: AppSpacing.lg),
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
        final githubError = await controller.syncGithub(userId: updated.id, username: githubUsername);
        if (githubError != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(githubError), backgroundColor: AppColors.googleRed),
          );
        }
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

class _AvatarPicker extends ConsumerStatefulWidget {
  const _AvatarPicker({required this.user});
  final AppUser user;

  @override
  ConsumerState<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<_AvatarPicker> {
  bool _uploading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (file == null) return;

    setState(() => _uploading = true);
    final error = await ref.read(profileEditControllerProvider.notifier).uploadAvatar(
          userId: widget.user.id,
          file: file,
        );
    if (mounted) {
      setState(() => _uploading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.googleRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestUser = ref.watch(currentUserProvider).valueOrNull ?? widget.user;
    return Center(
      child: GestureDetector(
        onTap: _uploading ? null : _pick,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.googleBlue,
              backgroundImage: latestUser.avatarUrl != null ? NetworkImage(latestUser.avatarUrl!) : null,
              child: _uploading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : latestUser.avatarUrl == null
                      ? Text(latestUser.initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.googleBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
