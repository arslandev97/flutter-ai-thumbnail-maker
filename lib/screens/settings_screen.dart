import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_theme.dart';
import 'change_password_screen.dart';
import 'about_app_screen.dart';
import 'about_developer_screen.dart';
import '../widgets/gradient_icon.dart';
import '../widgets/gradient_switch.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricEnabled = false;
  bool _isLoading = true;
  bool _isSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await _biometricService.isBiometricEnabled();
    final supported = await _biometricService.isDeviceSupported();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = enabled;
        _isSupported = supported;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable Biometric
      await _showPasswordDialog();
    } else {
      // Disable Biometric
      await _biometricService.clearCredentials();
      setState(() => _isBiometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || user.email == null) return;

    // If user signed in with Google, they might not have a password
    // For this MVP, we'll just show a warning if they try to enable it
    // Ideally, we'd check provider data, but for now let's assume email/pass
    // If verification fails, it handles it.

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Verify Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your current password to enable biometric login.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;

              Navigator.pop(context); // Close dialog

              try {
                // 1. Verify Password
                await authProvider.verifyCredentials(user.email!, password);

                // 2. Verify Biometric
                final authenticated = await _biometricService.authenticate();
                if (authenticated) {
                  // 3. Store Credentials
                  await _biometricService.storeCredentials(
                    user.email!,
                    password,
                  );

                  if (mounted) {
                    setState(() => _isBiometricEnabled = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric login enabled! 🔒'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric authentication failed'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Verification failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null || user.email == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Current Password',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'New Password',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPass = currentPasswordController.text.trim();
              final newPass = newPasswordController.text.trim();

              if (currentPass.isEmpty || newPass.isEmpty) return;

              Navigator.pop(context);

              try {
                await authProvider.verifyCredentials(user.email!, currentPass);
                await user.updatePassword(newPass);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully! 🔒'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update password: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('About App', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              height: 60,
              width: 60,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Thumbnail Maker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDeveloperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'About Developer',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Muhammad Arslan'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Bahawalpur, Punjab, Pakistan'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, 'hello@arslandev.com'),
            const SizedBox(height: 16),
            const Text(
              'Crafting digital experiences with passion and code. Turning ideas into reality, one pixel at a time. ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentCyan),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isSupported)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Biometric authentication is not supported on this device.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: const Text(
              'Biometric Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Use fingerprint or face ID to log in',
              style: TextStyle(color: Colors.white70),
            ),
            leading: const GradientIcon(Icons.fingerprint, size: 28),
            trailing: GradientSwitch(
              value: _isBiometricEnabled,
              onChanged: _isSupported ? _toggleBiometric : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => _navigateToScreen(const ChangePasswordScreen()),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: Icons.info_outline,
          title: 'About App',
          subtitle: 'Version and app info',
          onTap: () => _navigateToScreen(const AboutAppScreen()),
        ),
        const SizedBox(height: 16),
        _buildSettingsTile(
          icon: Icons.code,
          title: 'About Developer',
          subtitle: 'Meet the creator',
          onTap: () => _navigateToScreen(const AboutDeveloperScreen()),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: GradientIcon(icon, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
