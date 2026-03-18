import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _senderAddresses = [];
  List<dynamic> _receiverAddresses = [];

  bool _isLoadingSenders = true;
  bool _isLoadingReceivers = true;
  String? _sendersError;
  String? _receiversError;

  int _selectedTab = 0;

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    await Future.wait([_loadSenderAddresses(), _loadReceiverAddresses()]);
  }

  Future<void> _loadSenderAddresses() async {
    setState(() {
      _isLoadingSenders = true;
      _sendersError = null;
    });

    try {
      final addresses = await _apiService.getSenderAddresses();
      setState(() {
        _senderAddresses = addresses;
        _isLoadingSenders = false;
      });
    } catch (e) {
      setState(() {
        _sendersError = e.toString();
        _isLoadingSenders = false;
      });
    }
  }

  Future<void> _loadReceiverAddresses() async {
    setState(() {
      _isLoadingReceivers = true;
      _receiversError = null;
    });

    try {
      final addresses = await _apiService.getReceiverAddresses();
      setState(() {
        _receiverAddresses = addresses;
        _isLoadingReceivers = false;
      });
    } catch (e) {
      setState(() {
        _receiversError = e.toString();
        _isLoadingReceivers = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      appBar: AppBar(
        title: const Text(
          'Saved Addresses',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorConstants.red,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _buildTabButton('Sender Addresses', 0),
                _buildTabButton('Receiver Addresses', 1),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: ColorConstants.red,
        child: _selectedTab == 0
            ? _buildSenderAddressesList()
            : _buildReceiverAddressesList(),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderAddressesList() {
    if (_isLoadingSenders) {
      return const Center(
        child: CircularProgressIndicator(color: ColorConstants.red),
      );
    }

    if (_sendersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error loading sender addresses'),
            const SizedBox(height: 8),
            Text(_sendersError!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSenderAddresses,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.red,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_senderAddresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No sender addresses found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _senderAddresses.length,
      itemBuilder: (context, index) {
        final address = _senderAddresses[index];
        return _buildSenderAddressCard(address);
      },
    );
  }

  Widget _buildReceiverAddressesList() {
    if (_isLoadingReceivers) {
      return const Center(
        child: CircularProgressIndicator(color: ColorConstants.red),
      );
    }

    if (_receiversError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Error loading receiver addresses'),
            const SizedBox(height: 8),
            Text(_receiversError!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReceiverAddresses,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.red,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_receiverAddresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No receiver addresses found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receiverAddresses.length,
      itemBuilder: (context, index) {
        final address = _receiverAddresses[index];
        return _buildReceiverAddressCard(address);
      },
    );
  }

  Widget _buildSenderAddressCard(Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.red.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.blue, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'SENDER ADDRESS #${address['id']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${address['id']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.person_outline,
                        label: address['sender_name'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.phone_outlined,
                        label: address['phone_number'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildAddressDetail(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: address['address'] ?? 'N/A',
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),

                if (address['landmark'] != null &&
                    address['landmark'].isNotEmpty)
                  _buildAddressDetail(
                    icon: Icons.landscape_outlined,
                    label: 'Landmark',
                    value: address['landmark'],
                    color: Colors.grey,
                  ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.location_city,
                        value: address['district'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.map,
                        value: address['state'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.public,
                        value: address['country'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.markunread_mailbox,
                        value: address['zip_code'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${address['latitude'] ?? 'N/A'}, ${address['longitude'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(address['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiverAddressCard(Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.red.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RECEIVER ADDRESS #${address['id']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${address['id']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.person_outline,
                        label: address['receiver_name'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.phone_outlined,
                        label: address['receiver_phone'] ?? 'N/A',
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Address line
                _buildAddressDetail(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: address['address_text'] ?? 'N/A',
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),

                // Landmark
                if (address['landmark'] != null &&
                    address['landmark'].isNotEmpty)
                  _buildAddressDetail(
                    icon: Icons.landscape_outlined,
                    label: 'Landmark',
                    value: address['landmark'],
                    color: Colors.grey,
                  ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.location_city,
                        value: address['district'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.map,
                        value: address['state'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.public,
                        value: address['country'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildLocationChip(
                        icon: Icons.markunread_mailbox,
                        value: address['zip_code'] ?? 'N/A',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${address['latitude'] ?? 'N/A'}, ${address['longitude'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Created by: ${address['created_by'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(address['created_at']),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return _dateFormat.format(date);
    } catch (e) {
      return dateString;
    }
  }
}
