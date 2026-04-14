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
        ..._buildTimeline(
          timeline,
        ), // This will use the filtered timeline internally
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
    // Filter out assigned status events
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
    Map<String, List<Map<String, dynamic>>> carrierSegments = {};
    String? currentCarrier;

    // Group timeline events by carrier
    for (var event in filteredTimeline) {
      final eventMap = Map<String, dynamic>.from(event);
      Map<String, dynamic>? carrierDetails;

      // Extract carrier details based on event structure
      if (eventMap["details"] != null) {
        if (eventMap["details"].containsKey("carrier")) {
          carrierDetails = eventMap["details"]["carrier"];
        } else if (eventMap["details"].containsKey("id") &&
            !eventMap["details"].containsKey("shop_id")) {
          carrierDetails = eventMap["details"];
        }
      }

      final carrierKey = carrierDetails != null
          ? "${carrierDetails["id"]}_${carrierDetails["name"]}"
          : null;

      if (carrierKey != null && carrierKey != currentCarrier) {
        currentCarrier = carrierKey;
        if (!carrierSegments.containsKey(currentCarrier)) {
          carrierSegments[currentCarrier] = [];
        }
      }

      if (currentCarrier != null) {
        carrierSegments[currentCarrier]!.add(eventMap);
      } else {
        if (!carrierSegments.containsKey("no_carrier")) {
          carrierSegments["no_carrier"] = [];
        }
        carrierSegments["no_carrier"]!.add(eventMap);
      }
    }

    // Build UI for each carrier segment
    int segmentIndex = 0;
    carrierSegments.forEach((carrierKey, events) {
      // Get carrier details from the first event that has them
      Map<String, dynamic>? carrierDetails;
      Map<String, dynamic>? shopDetails;

      for (var event in events) {
        if (event["details"] != null) {
          if (event["details"].containsKey("carrier")) {
            carrierDetails = event["details"]["carrier"];
            if (event["details"].containsKey("shop")) {
              shopDetails = event["details"]["shop"];
            }
          } else if (event["details"].containsKey("id") &&
              !event["details"].containsKey("shop_id") &&
              carrierDetails == null) {
            carrierDetails = event["details"];
          }
          if (event["details"].containsKey("shop_id") && shopDetails == null) {
            shopDetails = event["details"];
          }
        }
      }

      if (segmentIndex > 0 && carrierDetails != null) {
        widgets.add(_carrierTransitionDivider());
      }

      if (carrierDetails != null && carrierKey != "no_carrier") {
        widgets.add(_carrierInfoCard(carrierDetails));
      }

      // Add shop info card if shop details exist
      if (shopDetails != null) {
        widgets.add(_shopInfoCard(shopDetails));
      }

      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final isLast =
            i == events.length - 1 &&
            segmentIndex == carrierSegments.length - 1;
        widgets.add(_timelineItem(event, isLast: isLast));
      }

      segmentIndex++;
    });

    return widgets;
  }

  Widget _carrierInfoCard(Map<String, dynamic>? carrier) {
    if (carrier == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(Icons.local_shipping, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                "Delivery Partner",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            carrier["name"] ?? "N/A",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (carrier["phone"] != null)
            Text(
              "Phone: ${carrier["phone"]}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (carrier["email"] != null)
            Text(
              "Email: ${carrier["email"]}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _shopInfoCard(Map<String, dynamic>? shop) {
    if (shop == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(Icons.store, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                "Shop Details",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            shop["shop_name"] ?? shop["name"] ?? "N/A",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (shop["owner_name"] != null)
            Text(
              "Owner: ${shop["owner_name"]}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (shop["phone"] != null)
            Text(
              "Phone: ${shop["phone"]}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (shop["category"] != null)
            Text(
              "Category: ${shop["category"]}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (shop["address"] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Address:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (shop["address"]["address"] != null)
                    Text(
                      shop["address"]["address"],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (shop["address"]["landmark"] != null)
                    Text(
                      "Landmark: ${shop["address"]["landmark"]}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (shop["address"]["district"] != null)
                    Text(
                      "${shop["address"]["district"]}, ${shop["address"]["state"]}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    final details = event["details"] as Map<String, dynamic>?;

    String title = _getStatusTitle(status, actor);
    String subtitle = _getStatusSubtitle(status, actor);
    IconData icon = _getStatusIcon(status, actor);
    Color color = _getStatusColor(status, actor);

    
    // ignore: unused_local_variable
    Map<String, dynamic>? displayDetails;
    if (details != null) {
      if (details.containsKey("carrier")) {
        displayDetails = details["carrier"];
      } else if (details.containsKey("id") && !details.containsKey("shop_id")) {
        displayDetails = details;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
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
                    height: 60,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                if (time != null)
                  Text(
                    _formatDateTime(time),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusSubtitle(String status, String? actor) {
    switch (status.toLowerCase()) {
      case "pending":
        if (actor == "sender") {
          return "Looking for available delivery partners in your area";
        } else if (actor == "carrier") {
          return "Delivery partner is on the way to pickup location";
        } else {
          return "Waiting for initial processing";
        }

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

      case "exception":
        return "An unexpected issue has occurred with your delivery";

      case "info_received":
        return "Shipping information has been received";

      case "manifested":
        return "Shipment has been manifested for delivery";

      case "received":
        return "Shipment has been received at facility";

      case "processed":
        return "Shipment is being processed";

      case "dispatched":
        return "Shipment has been dispatched from facility";

      case "clearance":
        return "Package is going through customs clearance";

      case "held":
        return "Shipment is temporarily on hold";

      case "rescheduled":
        return "Delivery has been rescheduled";

      case "return_to_sender":
        return "Package is being returned to sender";

      default:
        return "";
    }
  }

  List<dynamic> _filterTimeline(List<dynamic> timeline) {
    // Filter out events with status "assigned"
    return timeline.where((event) {
      final status = event["status"] as String? ?? "";
      return status.toLowerCase() != "assigned";
    }).toList();
  }

  String _getStatusTitle(String status, String? actor) {
    if (status.toLowerCase() == "pending") {
      if (actor == "sender") {
        return "Searching for Delivery Partner";
      } else if (actor == "carrier") {
        return "Partner En Route to Pickup";
      } else {
        return "Pending";
      }
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

  IconData _getStatusIcon(String status, String? actor) {
    if (status.toLowerCase() == "pending") {
      if (actor == "sender") {
        return Icons.search;
      } else if (actor == "carrier") {
        return Icons.directions_car;
      } else {
        return Icons.pending_actions;
      }
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
      if (actor == "sender") {
        return Colors.amber;
      } else if (actor == "carrier") {
        return Colors.blue;
      } else {
        return Colors.orange;
      }
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


  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateTimeStr;
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
