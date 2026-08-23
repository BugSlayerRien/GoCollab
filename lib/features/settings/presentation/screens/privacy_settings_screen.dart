import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/settings_widgets.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showProfile = true;
  bool _showEventHistory = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Control how your profile and activity appear to other GoCollab members.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SettingsSectionHeader('Profile visibility'),
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.visibility_outlined,
                title: 'Show profile to members',
                subtitle: 'Other chapter members can view your public profile.',
                value: _showProfile,
                onChanged: (v) => setState(() => _showProfile = v),
              ),
              SettingsSwitchTile(
                icon: Icons.event_outlined,
                title: 'Show event history',
                subtitle: 'Display events you have registered for on your profile.',
                value: _showEventHistory,
                onChanged: (v) => setState(() => _showEventHistory = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
