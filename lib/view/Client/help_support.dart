import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';
  final List<String> _categories = [
    'General Inquiry',
    'Order Issue',
    'Payment Problem',
    'Technical Support',
    'Account Issue',
    'Feedback',
  ];

  List<Map<String, dynamic>> _filteredFaqs = [];
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I track my order?',
      'answer':
          'You can track your order by going to "My Orders" section and clicking on the "Track" button next to your order. You\'ll see real-time location of your delivery partner.',
      'category': 'orders',
      'icon': Icons.track_changes,
    },
    {
      'question': 'How can I cancel my order?',
      'answer':
          'To cancel an order, go to "My Orders", select the order you want to cancel, and click on "Cancel Order" button. Cancellation is only possible before the order is picked up by the delivery partner.',
      'category': 'orders',
      'icon': Icons.cancel_outlined,
    },
    {
      'question': 'What payment methods do you accept?',
      'answer':
          'We accept all major credit/debit cards, UPI, net banking, and digital wallets. You can also pay with cash to the delivery partner.',
      'category': 'payments',
      'icon': Icons.payment,
    },
    {
      'question': 'How do I change my delivery address?',
      'answer':
          'You can change the delivery address while placing the order. For existing orders, please contact support immediately as address changes may not be possible once the order is in transit.',
      'category': 'orders',
      'icon': Icons.location_on_outlined,
    },
    {
      'question': 'What is your refund policy?',
      'answer':
          'Refunds are processed within 5-7 business days for cancelled orders or damaged items. The amount will be credited to your original payment method.',
      'category': 'payments',
      'icon': Icons.currency_rupee,
    },
    {
      'question': 'How do I become a delivery partner?',
      'answer':
          'Download the QDel Carrier app from Play Store, register with your details, and upload the required documents. Your application will be verified within 24-48 hours.',
      'category': 'account',
      'icon': Icons.delivery_dining,
    },
    {
      'question': 'Why was my account suspended?',
      'answer':
          'Accounts may be suspended due to multiple failed delivery attempts, suspicious activity, or violation of terms. Please contact support for specific details about your account.',
      'category': 'account',
      'icon': Icons.block,
    },
    {
      'question': 'How do I update my profile information?',
      'answer':
          'Go to Profile section, click on "Edit Profile" to update your name, email, or phone number. For address changes, manage them in the "Saved Addresses" section.',
      'category': 'account',
      'icon': Icons.person_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _faqs;
    _searchController.addListener(_filterFaqs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _faqs;
      } else {
        _filteredFaqs = _faqs.where((faq) {
          return faq['question'].toLowerCase().contains(query) ||
              faq['answer'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConstants.red,
              ),
            ),
            const SizedBox(height: 20),
            _buildContactOption(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+91 98765 43210',
              color: Colors.green,
              onTap: () => _launchURL('tel:+919876543210'),
            ),
            _buildContactOption(
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: 'support@qdel.com',
              color: Colors.blue,
              onTap: () => _launchURL('mailto:support@qdel.com'),
            ),
            _buildContactOption(
              icon: Icons.chat_outlined,
              title: 'Live Chat',
              subtitle: '24/7 instant support',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showChatBottomSheet();
              },
            ),
            _buildContactOption(
              icon: Icons.app_blocking_outlined,
              title: 'WhatsApp',
              subtitle: 'Quick support on WhatsApp',
              color: Colors.green.shade700,
              onTap: () => _launchURL('https://wa.me/919876543210'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey.shade400,
      ),
    );
  }

  void _showChatBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Live Chat Support',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: ColorConstants.red,
                      child: Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Agent',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Typically replies in a few minutes',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hello! How can we help you today? Please describe your issue and we\'ll get back to you shortly.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ColorConstants.red),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Message sent! Support will reply soon.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _messageController.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Send Message',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaqAnswer(Map<String, dynamic> faq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConstants.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(faq['icon'], color: ColorConstants.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                faq['question'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          faq['answer'],
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showContactOptions();
            },
            child: const Text(
              'Need More Help?',
              style: TextStyle(color: ColorConstants.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.white,
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                      Icons.help_outline,
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
                          'How can we help you?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Find answers to common questions or contact our support team',
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

            // Search FAQs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for answers...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Contact Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickContactButton(
                      icon: Icons.phone_outlined,
                      label: 'Call',
                      color: Colors.green,
                      onTap: () => _launchURL('tel:+919876543210'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickContactButton(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      color: Colors.blue,
                      onTap: () => _launchURL('mailto:support@qdel.com'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickContactButton(
                      icon: Icons.chat_outlined,
                      label: 'Chat',
                      color: Colors.orange,
                      onTap: _showChatBottomSheet,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Support Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConstants.red,
                      ColorConstants.red.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Need Immediate Help?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Our support team is available 24/7',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _showContactOptions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ColorConstants.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Contact Support'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FAQs Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorConstants.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help,
                      color: ColorConstants.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // FAQ Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip('All', true),
                  _buildCategoryChip('Orders', false),
                  _buildCategoryChip('Payments', false),
                  _buildCategoryChip('Account', false),
                  _buildCategoryChip('Technical', false),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // FAQ List
            _filteredFaqs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matching questions found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different keywords or contact support',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return _buildFaqTile(faq);
                    },
                  ),

            const SizedBox(height: 20),

            // Report Issue Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _showChatBottomSheet();
                },
                icon: const Icon(Icons.flag_outlined, color: Colors.red),
                label: const Text(
                  'Report an Issue',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

  Widget _buildQuickContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {},
        backgroundColor: Colors.grey.shade100,
        selectedColor: ColorConstants.red.withOpacity(0.2),
        checkmarkColor: ColorConstants.red,
        labelStyle: TextStyle(
          color: isSelected ? ColorConstants.red : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? ColorConstants.red : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        onTap: () => _showFaqAnswer(faq),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConstants.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(faq['icon'], color: ColorConstants.red, size: 20),
        ),
        title: Text(
          faq['question'],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          faq['answer'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
