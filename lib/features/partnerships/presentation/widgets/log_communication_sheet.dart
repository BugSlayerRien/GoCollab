import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/partnership_providers.dart';

void showLogCommunicationSheet(BuildContext context, {required String partnerId, required String communicatedBy}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _LogCommunicationSheet(partnerId: partnerId, communicatedBy: communicatedBy),
  );
}

class _LogCommunicationSheet extends ConsumerStatefulWidget {
  const _LogCommunicationSheet({required this.partnerId, required this.communicatedBy});
  final String partnerId;
  final String communicatedBy;

  @override
  ConsumerState<_LogCommunicationSheet> createState() => _LogCommunicationSheetState();
}

class _LogCommunicationSheetState extends ConsumerState<_LogCommunicationSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _direction = 'outbound';
  String _method = 'email';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
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
            Text('Log communication', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Subject', controller: _subjectController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Notes', controller: _messageController, maxLines: 3),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _direction,
                    decoration: const InputDecoration(labelText: 'Direction'),
                    items: const ['outbound', 'inbound'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _direction = v ?? 'outbound'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: const ['email', 'call', 'meeting', 'chat', 'other']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v ?? 'email'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Save log',
              isLoading: isSubmitting,
              onPressed: () async {
                if (_subjectController.text.trim().isEmpty) return;
                final success = await ref.read(partnershipActionsControllerProvider.notifier).createCommunication(
                      partnerId: widget.partnerId,
                      subject: _subjectController.text.trim(),
                      message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
                      direction: _direction,
                      contactMethod: _method,
                      communicatedBy: widget.communicatedBy,
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
