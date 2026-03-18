import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // Security settings
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _loginAlertsEnabled = true;
  bool _saveLoginHistory = true;
  
  // Privacy settings
  bool _shareDataAnonymous = false;
  bool _personalizedAds = true;
  bool _locationTracking = true;
  bool _activityStatus = true;
  
  // Session management
  bool _rememberMe = true;
  String _sessionTimeout = '30 minutes';
  final List<String> _timeoutOptions = ['15 minutes', '30 minutes', '1 hour', 'Never'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorConstants.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstants.red.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.security,
                      color: ColorConstants.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy & Security',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your account security and privacy preferences',
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstants.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Account Security Section
            _buildSectionHeader(
              title: 'Account Security',
              icon: Icons.shield_outlined,
            ),
            
            _buildSwitchTile(
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face ID to login',
              value: _biometricEnabled,
              onChanged: (value) => setState(() => _biometricEnabled = value),
              icon: Icons.fingerprint,
              iconColor: Colors.blue,
            ),
            
            _buildSwitchTile(
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              value: _twoFactorEnabled,
              onChanged: (value) => setState(() => _twoFactorEnabled = value),
              icon: Icons.verified_user_outlined,
              iconColor: Colors.green,
            ),
            
            _buildSwitchTile(
              title: 'Login Alerts',
              subtitle: 'Get notified of new sign-ins',
              value: _loginAlertsEnabled,
              onChanged: (value) => setState(() => _loginAlertsEnabled = value),
              icon: Icons.notifications_active_outlined,
              iconColor: Colors.orange,
            ),

            const SizedBox(height: 8),
            
            // Change Password Tile
            _buildActionTile(
              title: 'Change Password',
              subtitle: 'Update your account password',
              icon: Icons.lock_outline,
              iconColor: Colors.red,
              onTap: () => _showChangePasswordDialog(context),
            ),

            const SizedBox(height: 16),

            // Session Management Section
            _buildSectionHeader(
              title: 'Session Management',
              icon: Icons.devices_outlined,
            ),
            
            _buildSwitchTile(
              title: 'Remember Me',
              subtitle: 'Stay logged in on this device',
              value: _rememberMe,
              onChanged: (value) => setState(() => _rememberMe = value),
              icon: Icons.check_circle_outline,
              iconColor: Colors.purple,
            ),
            
            _buildDropdownTile(
              title: 'Session Timeout',
              subtitle: 'Auto logout after inactivity',
              value: _sessionTimeout,
              options: _timeoutOptions,
              onChanged: (value) => setState(() => _sessionTimeout = value!),
              icon: Icons.timer_outlined,
              iconColor: Colors.teal,
            ),
            
            _buildSwitchTile(
              title: 'Save Login History',
              subtitle: 'Keep track of your login sessions',
              value: _saveLoginHistory,
              onChanged: (value) => setState(() => _saveLoginHistory = value),
              icon: Icons.history,
              iconColor: Colors.indigo,
            ),

            const SizedBox(height: 16),

            // Active Sessions Tile
            _buildActionTile(
              title: 'Active Sessions',
              subtitle: 'Manage devices where you\'re logged in',
              icon: Icons.devices_other,
              iconColor: Colors.blue,
              onTap: () => _showActiveSessionsDialog(context),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1 Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Controls Section
            _buildSectionHeader(
              title: 'Privacy Controls',
              icon: Icons.privacy_tip_outlined,
            ),
            
            _buildSwitchTile(
              title: 'Share Anonymous Data',
              subtitle: 'Help us improve by sharing usage data',
              value: _shareDataAnonymous,
              onChanged: (value) => setState(() => _shareDataAnonymous = value),
              icon: Icons.analytics_outlined,
              iconColor: Colors.brown,
            ),
            
            _buildSwitchTile(
              title: 'Personalized Ads',
              subtitle: 'See relevant advertisements',
              value: _personalizedAds,
              onChanged: (value) => setState(() => _personalizedAds = value),
              icon: Icons.ads_click,
              iconColor: Colors.pink,
            ),
            
            _buildSwitchTile(
              title: 'Location Tracking',
              subtitle: 'Allow app to access your location',
              value: _locationTracking,
              onChanged: (value) => setState(() => _locationTracking = value),
              icon: Icons.location_on_outlined,
              iconColor: Colors.cyan,
            ),
            
            _buildSwitchTile(
              title: 'Activity Status',
              subtitle: 'Show when you\'re active',
              value: _activityStatus,
              onChanged: (value) => setState(() => _activityStatus = value),
              icon: Icons.circle_outlined,
              iconColor: Colors.deepPurple,
            ),

            const SizedBox(height: 16),

            // Data Management Section
            _buildSectionHeader(
              title: 'Data Management',
              icon: Icons.data_usage,
            ),
            
            _buildActionTile(
              title: 'Download My Data',
              subtitle: 'Get a copy of your personal data',
              icon: Icons.download_outlined,
              iconColor: Colors.green,
              onTap: () => _showDownloadDataDialog(context),
            ),
            
            _buildActionTile(
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              icon: Icons.delete_forever_outlined,
              iconColor: Colors.red,
              onTap: () => _showDeleteAccountDialog(context),
            ),

            const SizedBox(height: 30),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [ColorConstants.red, Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy settings saved!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorConstants.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: ColorConstants.red,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorConstants.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: ColorConstants.red,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: ColorConstants.red),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActiveSessionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.devices, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Text(
              'Active Sessions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildSessionTile(
                device: 'iPhone 14 Pro',
                location: 'Kochi, India',
                time: 'Now',
                isCurrent: true,
              ),
              const Divider(),
              _buildSessionTile(
                device: 'Windows PC - Chrome',
                location: 'Kochi, India',
                time: '2 hours ago',
                isCurrent: false,
              ),
              const Divider(),
              _buildSessionTile(
                device: 'iPad Air',
                location: 'Kochi, India',
                time: 'Yesterday',
                isCurrent: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All other sessions signed out'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Sign Out All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile({
    required String device,
    required String location,
    required String time,
    required bool isCurrent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              device.contains('iPhone') ? Icons.phone_iphone :
              device.contains('iPad') ? Icons.tablet_mac :
              Icons.computer,
              color: isCurrent ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text(
              'Download My Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You can request a copy of your personal data. We\'ll prepare a ZIP file containing:',
            ),
            const SizedBox(height: 16),
            _buildDataOption('Profile Information', true),
            _buildDataOption('Order History', true),
            _buildDataOption('Saved Addresses', true),
            _buildDataOption('Payment Methods', false),
            _buildDataOption('Communication Logs', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data export started. You\'ll receive an email when ready.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Request Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(String label, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.cancel,
            color: included ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: included ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Account',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Your profile and personal information'),
            Text('• All your orders and history'),
            Text('• Saved addresses and payment methods'),
            SizedBox(height: 16),
            Text(
              'Are you sure you want to continue?',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Enter Password'),
                  content: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deletion requested. Check your email to confirm.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}