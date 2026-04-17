import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  
  bool _orderUpdates = true;
  bool _orderStatus = true;
  bool _deliveryUpdates = true;
  bool _cancellations = true;
  
  bool _offersAndPromos = false;
  bool _newsletter = false;
  
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _quietStart : _quietEnd,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorConstants.red,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
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
                      Icons.notifications_active,
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
                          'Notification Preferences',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage how you receive notifications',
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

            _buildSectionHeader(
              title: 'Notification Channels',
              icon: Icons.notifications_outlined,
            ),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: _pushEnabled,
              onChanged: (value) => setState(() => _pushEnabled = value),
              icon: Icons.phone_android,
              iconColor: Colors.blue,
            ),
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _emailEnabled,
              onChanged: (value) => setState(() => _emailEnabled = value),
              icon: Icons.email_outlined,
              iconColor: Colors.orange,
            ),
            _buildSwitchTile(
              title: 'SMS Notifications',
              subtitle: 'Receive notifications via text message',
              value: _smsEnabled,
              onChanged: (value) => setState(() => _smsEnabled = value),
              icon: Icons.sms_outlined,
              iconColor: Colors.green,
            ),

            const SizedBox(height: 16),

            _buildSectionHeader(
              title: 'Order Updates',
              icon: Icons.shopping_bag_outlined,
            ),
            _buildSwitchTile(
              title: 'Order Confirmation',
              subtitle: 'Get notified when order is placed',
              value: _orderUpdates,
              onChanged: (value) => setState(() => _orderUpdates = value),
              icon: Icons.check_circle_outline,
              iconColor: Colors.purple,
            ),
            _buildSwitchTile(
              title: 'Status Changes',
              subtitle: 'Order status updates (processing, shipped, etc.)',
              value: _orderStatus,
              onChanged: (value) => setState(() => _orderStatus = value),
              icon: Icons.trending_up,
              iconColor: Colors.teal,
            ),
            _buildSwitchTile(
              title: 'Delivery Updates',
              subtitle: 'Real-time delivery tracking notifications',
              value: _deliveryUpdates,
              onChanged: (value) => setState(() => _deliveryUpdates = value),
              icon: Icons.local_shipping_outlined,
              iconColor: Colors.indigo,
            ),
            _buildSwitchTile(
              title: 'Cancellations',
              subtitle: 'Get notified about order cancellations',
              value: _cancellations,
              onChanged: (value) => setState(() => _cancellations = value),
              icon: Icons.cancel_outlined,
              iconColor: Colors.red,
            ),

            const SizedBox(height: 16),

            _buildSectionHeader(
              title: 'Promotions & Updates',
              icon: Icons.local_offer_outlined,
            ),
            _buildSwitchTile(
              title: 'Offers & Promos',
              subtitle: 'Special discounts and promotional offers',
              value: _offersAndPromos,
              onChanged: (value) => setState(() => _offersAndPromos = value),
              icon: Icons.discount_outlined,
              iconColor: Colors.pink,
            ),
            _buildSwitchTile(
              title: 'Newsletter',
              subtitle: 'Weekly updates and news',
              value: _newsletter,
              onChanged: (value) => setState(() => _newsletter = value),
              icon: Icons.newspaper,
              iconColor: Colors.brown,
            ),

            const SizedBox(height: 16),

            _buildSectionHeader(
              title: 'Sound & Vibration',
              icon: Icons.volume_up_outlined,
            ),
            _buildSwitchTile(
              title: 'Notification Sound',
              subtitle: 'Play sound for notifications',
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
              icon: Icons.volume_up_outlined,
              iconColor: Colors.cyan,
            ),
            _buildSwitchTile(
              title: 'Vibration',
              subtitle: 'Vibrate for notifications',
              value: _vibrationEnabled,
              onChanged: (value) => setState(() => _vibrationEnabled = value),
              icon: Icons.vibration,
              iconColor: Colors.deepPurple,
            ),

            const SizedBox(height: 16),

            _buildSectionHeader(
              title: 'Quiet Hours',
              icon: Icons.nightlight_round,
            ),
            _buildSwitchTile(
              title: 'Enable Quiet Hours',
              subtitle: 'Mute notifications during specific hours',
              value: _quietHoursEnabled,
              onChanged: (value) => setState(() => _quietHoursEnabled = value),
              icon: Icons.bedtime_outlined,
              iconColor: Colors.deepOrange,
            ),
            
            if (_quietHoursEnabled) ...[
              _buildTimePickerTile(
                title: 'Start Time',
                time: _quietStart,
                onTap: () => _selectTime(context, true),
                icon: Icons.wb_twilight,
              ),
              _buildTimePickerTile(
                title: 'End Time',
                time: _quietEnd,
                onTap: () => _selectTime(context, false),
                icon: Icons.wb_sunny,
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorConstants.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: ColorConstants.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications will be muted from ${_quietStart.format(context)} to ${_quietEnd.format(context)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

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
                        content: Text('Notification settings saved!'),
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

  Widget _buildTimePickerTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
    required IconData icon,
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
                color: ColorConstants.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ColorConstants.red, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time.format(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}