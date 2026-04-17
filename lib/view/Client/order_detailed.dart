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
  ApiService apiService = ApiService();

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
                    _trackingSection(data["shipment"]),
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

    final address = data["sender_address"] as Map<String, dynamic>?;
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
    final address = data["receiver_address"] as Map<String, dynamic>?;
    return _card(
      title: "Receiver Details",
      icon: Icons.person_pin_circle,
      children: [
        _row("Name", address?["receiver_name"], Icons.person),
        _row("Phone", address?["receiver_phone"], Icons.phone),
        const Divider(),
        _row("Address", address?["address_text"], Icons.location_on),
        _row("District", address?["district"], Icons.location_city),
        _row("Country", address?["country"], Icons.flag),
      ],
    );
  }

  Widget _productSection(Map<String, dynamic>? data) {
    if (data == null) return const SizedBox.shrink();

    final product = data["product_details"] as Map<String, dynamic>?;

    final images = product?["images"] as List?;
    final String? imagePath = images != null && images.isNotEmpty
        ? images.first["image"]
        : null;

    final String? imageUrl = imagePath == null
        ? null
        : "${apiService.baseurl}$imagePath";

    return _card(
      title: "Product Details",
      icon: Icons.inventory_2,
      children: [
        _row("Name", product?["name"], Icons.shopping_bag),
        _row("Description", product?["description"], Icons.notes),
        _row("Weight", product?["actual_weight"], Icons.scale),
        _row("Volume", product?["volume"], Icons.straighten),
        const SizedBox(height: 12),
        _imagePreview(title: "Product Image", imageUrl: imageUrl),
      ],
    );
  }

  Widget _imagePreview({required String title, required String? imageUrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: imageUrl == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ImageZoomScreen(imageUrl: imageUrl),
                    ),
                  );
                },
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: imageUrl == null
                ? const Center(
                    child: Text(
                      "No image uploaded",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _trackingSection(Map<String, dynamic>? response) {
    if (response == null || response["data"] == null) {
      return _card(
        title: "Order Tracking",
        icon: Icons.track_changes,
        children: const [
          Text(
            "Tracking information not available",
            style: TextStyle(color: Colors.orange),
          ),
        ],
      );
    }

    final trackingData = response["data"];
    final trackingNo = trackingData["carrier_tracking_no"] ?? "N/A";
    final timeline =
        trackingData["tracking"]["timeline"] as List<dynamic>? ?? [];

    return _card(
      title: "Order Tracking",
      icon: Icons.track_changes,
      children: [
        _trackingHeader(trackingNo),
        const SizedBox(height: 16),
        ..._buildTimeline(timeline),
      ],
    );
  }

  Widget _trackingHeader(String trackingNo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tracking Number",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  trackingNo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(List<dynamic> timeline) {
    final filteredTimeline = _filterTimeline(timeline);

    if (filteredTimeline.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text("No tracking updates available"),
          ),
        ),
      ];
    }

    List<Widget> widgets = [];

    String? lastCarrierKey;

    for (int i = 0; i < filteredTimeline.length; i++) {
      final event = Map<String, dynamic>.from(filteredTimeline[i]);
      final status = (event["status"] as String? ?? "").toLowerCase();
      final actor = event["actor"] as String?;
      final details = event["details"] as Map<String, dynamic>?;
      final isLast = i == filteredTimeline.length - 1;

     
      if (status == "pending" && actor == "carrier" && details != null) {
        final carrierId = details["id"]?.toString();
        final carrierKey = carrierId != null ? "carrier_$carrierId" : null;

        if (carrierKey != null &&
            lastCarrierKey != null &&
            carrierKey != lastCarrierKey) {
          widgets.add(_carrierTransitionDivider());
        }

        if (carrierKey != null) {
          lastCarrierKey = carrierKey;
        }
      }

      widgets.add(_timelineItem(event, isLast: isLast));

      if (status == "pending" && actor == "carrier" && details != null) {
        final carrierDetails = _extractCarrierDetails(details);
        if (carrierDetails != null) {
          widgets.add(_inlineCarrierCard(carrierDetails));
        }
      }

     
      if (status == "dropped_at_shop" && details != null) {
        final shopDetails = _extractShopDetails(details);
        if (shopDetails != null) {
          widgets.add(_inlineShopCard(shopDetails));
        }
      }
    }

    return widgets;
  }

  Map<String, dynamic>? _extractCarrierDetails(Map<String, dynamic> details) {
    if (details.containsKey("carrier")) {
      return details["carrier"] as Map<String, dynamic>?;
    }
    if (details.containsKey("id") && !details.containsKey("shop_id")) {
      return details;
    }
    return null;
  }

  Map<String, dynamic>? _extractShopDetails(Map<String, dynamic> details) {
    if (details.containsKey("shop")) {
      return details["shop"] as Map<String, dynamic>?;
    }
    if (details.containsKey("shop_id")) {
      return details;
    }
    return null;
  }

 
  Widget _inlineCarrierCard(Map<String, dynamic> carrier) {
    return Container(
      margin: const EdgeInsets.only(left: 52, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                "Delivery Partner",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (carrier["name"] != null)
            _infoRow(Icons.person, carrier["name"]),
          if (carrier["phone"] != null)
            _infoRow(Icons.phone, carrier["phone"]),
          if (carrier["email"] != null)
            _infoRow(Icons.email, carrier["email"]),
        ],
      ),
    );
  }

  Widget _inlineShopCard(Map<String, dynamic> shop) {
    final address = shop["address"] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(left: 52, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                "Drop Shop",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (shop["shop_name"] != null)
            _infoRow(Icons.store, shop["shop_name"]),
          if (shop["owner_name"] != null)
            _infoRow(Icons.person, "Owner: ${shop["owner_name"]}"),
          if (shop["phone"] != null)
            _infoRow(Icons.phone, shop["phone"]),
          if (shop["category"] != null)
            _infoRow(Icons.category, shop["category"]),
          if (address != null) ...[
            const SizedBox(height: 6),
            if (address["address"] != null)
              _infoRow(Icons.location_on, address["address"]),
            if (address["landmark"] != null)
              _infoRow(
                  Icons.place, "Landmark: ${address["landmark"]}"),
            if (address["district"] != null || address["state"] != null)
              _infoRow(
                Icons.map,
                [address["district"], address["state"]]
                    .where((v) => v != null && v.toString().isNotEmpty)
                    .join(", "),
              ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carrierTransitionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Handover to new partner",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Container(height: 2, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _timelineItem(Map<String, dynamic> event, {bool isLast = false}) {
    final status = event["status"] as String? ?? "pending";
    final time = event["time"] as String?;
    final actor = event["actor"] as String?;

    final String title = _getStatusTitle(status, actor);
    final String subtitle = _getStatusSubtitle(status, actor);
    final IconData icon = _getStatusIcon(status, actor);
    final Color color = _getStatusColor(status, actor);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 2,
                    height: 50,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (time != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterTimeline(List<dynamic> timeline) {
    return timeline.where((event) {
      final status = event["status"] as String? ?? "";
      return status.toLowerCase() != "assigned";
    }).toList();
  }

  String _getStatusTitle(String status, String? actor) {
    if (status.toLowerCase() == "pending") {
      if (actor == "sender") return "Searching for Delivery Partner";
      if (actor == "carrier") return "Partner En Route to Pickup";
      return "Pending";
    }
    switch (status.toLowerCase()) {
      case "assigned":
        return "Partner Assigned";
      case "arrived":
        return "Partner Arrived at Pickup";
      case "picked_up":
        return "Package Picked Up";
      case "drop_assigned":
        return "Drop Partner Assigned";
      case "arrived_at_shop":
        return "Arrived at Drop Location";
      case "dropped_at_shop":
        return "Dropped at Shop";
      case "arrived_at_drop":
        return "Arrived at Delivery Location";
      case "delivered":
        return "Delivered Successfully";
      default:
        return _capitalize(status);
    }
  }

  String _getStatusSubtitle(String status, String? actor) {
    switch (status.toLowerCase()) {
      case "pending":
        if (actor == "sender") {
          return "Looking for available delivery partners in your area";
        } else if (actor == "carrier") {
          return "Delivery partner is on the way to pickup location";
        }
        return "Waiting for initial processing";
      case "assigned":
        return "A delivery partner has been assigned to your order";
      case "arrived":
        return "Delivery partner has reached the pickup location";
      case "picked_up":
        return "Package has been picked up and is on its way";
      case "drop_assigned":
        return "A drop partner has been assigned for final delivery";
      case "arrived_at_shop":
        return "Package has arrived at the drop location/shop";
      case "dropped_at_shop":
        return "Package has been dropped at the shop for processing";
      case "arrived_at_drop":
        return "Delivery partner has arrived at the delivery location";
      case "delivered":
        return "Package has been successfully delivered";
      case "in_transit":
        return "Package is in transit to the next facility";
      case "out_for_delivery":
        return "Package is out for final delivery";
      case "returned":
        return "Package has been returned to sender";
      case "cancelled":
        return "Order has been cancelled";
      case "failed":
        return "Delivery attempt was unsuccessful";
      default:
        return "";
    }
  }

  IconData _getStatusIcon(String status, String? actor) {
    if (status.toLowerCase() == "pending") {
      if (actor == "sender") return Icons.search;
      if (actor == "carrier") return Icons.directions_car;
      return Icons.pending_actions;
    }
    switch (status.toLowerCase()) {
      case "assigned":
        return Icons.person_add;
      case "arrived":
        return Icons.location_on;
      case "picked_up":
        return Icons.inventory_2;
      case "drop_assigned":
        return Icons.swap_horiz;
      case "arrived_at_shop":
        return Icons.store;
      case "dropped_at_shop":
        return Icons.storefront;
      case "arrived_at_drop":
        return Icons.location_pin;
      case "delivered":
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status, String? actor) {
    if (status.toLowerCase() == "pending") {
      if (actor == "sender") return Colors.amber;
      if (actor == "carrier") return Colors.blue;
      return Colors.orange;
    }
    switch (status.toLowerCase()) {
      case "assigned":
        return Colors.purple;
      case "arrived":
        return Colors.indigo;
      case "picked_up":
        return Colors.teal;
      case "drop_assigned":
        return Colors.cyan;
      case "arrived_at_shop":
        return Colors.lightBlue;
      case "dropped_at_shop":
        return Colors.green;
      case "arrived_at_drop":
        return Colors.lightGreen;
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
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
        ),
      ],
    );
  }

  Widget _row(String label, dynamic value, IconData icon) {
    final display =
        value == null || value.toString().isEmpty ? "-" : value.toString();

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

class _ImageZoomScreen extends StatelessWidget {
  final String imageUrl;
  const _ImageZoomScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}