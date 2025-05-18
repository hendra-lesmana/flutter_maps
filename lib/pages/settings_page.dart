import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Account Section
                _buildSectionTitle('Account'),
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  subtitle: 'Manage your account information',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: 'Password and authentication',
                  onTap: () {},
                ),
                
                const SizedBox(height: 24),
                
                // Preferences Section
                _buildSectionTitle('Preferences'),
                _buildSwitchTile(
                  icon: Icons.notifications_none,
                  title: 'Push Notifications',
                  subtitle: 'Receive alerts and updates',
                  value: true,
                  onChanged: (bool value) {},
                ),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  value: false,
                  onChanged: (bool value) {},
                ),
                
                const SizedBox(height: 24),
                
                // Privacy Section
                _buildSectionTitle('Privacy'),
                _buildSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location Services',
                  subtitle: 'Manage location permissions',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {},
                ),
                
                const SizedBox(height: 24),
                
                // About Section
                _buildSectionTitle('About'),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}