import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int pickupId;
  const OrderDetailsScreen({super.key, required this.pickupId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;

  @override
  void initState() {
    super.initState();
    debugPrint("🟢 OrderDetailsScreen init | pickupId = ${widget.pickupId}");
    _detailsFuture = _loadAllDetails();
  }

  Future<Map<String, dynamic>> _loadAllDetails() async {
    final api = ApiService();

    debugPrint("📡 Fetching all order details...");

    final sender = await api.getSenderDetails(widget.pickupId);
    debugPrint("📦 Sender API Response: $sender");

    final receiver = await api.getReceiverDetails(widget.pickupId);
    debugPrint("📦 Receiver API Response: $receiver");

    final product = await api.getProductDetails(widget.pickupId);
    debugPrint("📦 Product API Response: $product");

    final shipment = await api.getShipmentStatus(widget.pickupId);
    debugPrint("📦 Shipment API Response: $shipment");
    return {
      "sender": sender,
      "receiver": receiver,
      "product": product,
      "shipment": shipment,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7F7),
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint("⏳ Waiting for order details...");
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  debugPrint("❌ Snapshot has no data");
                  return const Center(
                    child: Text("Failed to load order details"),
                  );
                }

                final data = snapshot.data!;
                debugPrint("✅ All data loaded successfully");

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _senderSection(data["sender"]),
                    _receiverSection(data["receiver"]),
                    _productSection(data["product"]),
                    _shipmentSection(data["shipment"]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.only(top: 45, left: 16, right: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFFF6F60)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Order Details",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _senderSection(Map<String, dynamic>? data) {
    debugPrint("👤 Sender section data: $data");

    if (data == null) {
      debugPrint("⚠️ Sender data is NULL");
      return const SizedBox.shrink();
    }

    final sender = data["sender_details"] as Map<String, dynamic>?;
    final address = data["sender_address"] as Map<String, dynamic>?;
    debugPrint("👤 Sender Details: $sender");
    debugPrint("🏠 Sender Address: $address");
    return _card(
      title: "Sender Details",
      icon: Icons.person,
      children: [
        _row("Name", address?["sender_name"], Icons.person),
        _row("Phone", address?["phone_number"], Icons.phone),
        const Divider(),
        _row("Address", address?["address"], Icons.home),
        _row("District", address?["district"], Icons.location_city),
        _row("State", address?["state"], Icons.map),
        _row("Pincode", address?["zip_code"], Icons.pin),
      ],
    );
  }

  Widget _receiverSection(Map<String, dynamic>? data) {
    debugPrint("👥 Receiver section data: $data");
    if (data == null) return const SizedBox.shrink();
    final receiver = data["receiver_details"] as Map<String, dynamic>?;
    final address = data["receiver_address"] as Map<String, dynamic>?;
    return _card(
      title: "Receiver Details",
      icon: Icons.person_pin_circle,
      children: [
        _row("Name", receiver?["full_name"], Icons.person),
        _row("Phone", receiver?["phone"], Icons.phone),
        const Divider(),
        _row("Address", address?["address_text"], Icons.location_on),
        _row("District", address?["district"], Icons.location_city),
        _row("Country", address?["country"], Icons.flag),
      ],
    );
  }

  Widget _productSection(Map<String, dynamic>? data) {
    debugPrint("📦 Product section data: $data");

    if (data == null) return const SizedBox.shrink();

    final product = data["product_details"] as Map<String, dynamic>?;

    return _card(
      title: "Product Details",
      icon: Icons.inventory_2,
      children: [
        _row("Name", product?["name"], Icons.shopping_bag),
        _row("Description", product?["description"], Icons.notes),
        _row("Weight", product?["actual_weight"], Icons.scale),
        _row("Volume", product?["volume"], Icons.straighten),
      ],
    );
  }

  Widget _shipmentSection(Map<String, dynamic>? response) {
    debugPrint("🚚 Shipment section data: $response");

    if (response == null) return const SizedBox.shrink();

    final shipment = response["data"] as Map<String, dynamic>?;

    if (shipment == null) {
      debugPrint("⚠️ Shipment not created yet");
      return _card(
        title: "Delivery Partner",
        icon: Icons.local_shipping,
        children: const [
          Text(
            "Shipment not created yet",
            style: TextStyle(color: Colors.orange),
          ),
        ],
      );
    }

    final carrier = shipment["carrier"] as Map<String, dynamic>?;

    debugPrint("🚚 Shipment Status: ${shipment["status"]}");
    debugPrint("👤 Carrier Data: $carrier");

    return _card(
      title: "Delivery Partner",
      icon: Icons.local_shipping,
      children: [
        _row("Status", shipment["status"], Icons.info),
        _row("Tracking No", shipment["carrier_tracking_no"], Icons.qr_code),
        _row("Picked At", shipment["picked_at"], Icons.upload),
        _row("Delivered At", shipment["delivered_at"], Icons.check_circle),
        const Divider(),
        _row(
          "Partner",
          carrier == null
              ? "-"
              : "${carrier["first_name"] ?? ""} ${carrier["last_name"] ?? ""}"
                    .trim(),
          Icons.person,
        ),
        _row("Phone", carrier?["phone"], Icons.phone),
        _row("Email", carrier?["email"], Icons.email),
      ],
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _row(String label, dynamic value, IconData icon) {
    final display = value == null || value.toString().isEmpty
        ? "-"
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label)),
          Expanded(child: Text(display)),
        ],
      ),
    );
  }
}
