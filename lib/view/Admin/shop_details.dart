import 'package:flutter/material.dart';
import 'package:projectqdel/services/api_service.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ApiService apiService = ApiService();

  Map<String, dynamic>? shop;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    final data = await apiService.getShopDetailsByUserId(widget.shopId);

    setState(() {
      shop = data;
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.red,
      //   title: const Text("Shop Details"),
      // ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : shop == null
          ? const Center(child: Text("Failed to load shop"))
          : SingleChildScrollView(
              child: Column(
                children: [
                  /// 🔴 HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          (shop!['shop_name'] ?? "").toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            shop!['shop_approval_status'].toUpperCase(),
                            style: TextStyle(
                              color: getStatusColor(
                                shop!['shop_approval_status'],
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 👤 OWNER DETAILS
                  _infoCard(
                    title: "Owner Details",
                    children: [
                      _infoRow(
                        "Name",
                        "${shop!['first_name']} ${shop!['last_name']}"
                            .toUpperCase(),
                      ),
                      _infoRow("Email", shop!['email']),
                      _infoRow("Phone", shop!['phone']),
                    ],
                  ),

                  /// 📍 ADDRESS
                  _infoCard(
                    title: "Addresses",
                    children: (shop!['shop_addresses'] as List).map<Widget>((
                      addr,
                    ) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['address'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("Landmark: ${addr['landmark']}"),
                            Text("Zip: ${addr['zip_code']}"),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  /// 🖼️ IMAGES
                  _infoCard(
                    title: "Documents & Images",
                    children: [
                      if (shop!['shop_photo'] != null)
                        _imageCard(
                          "${apiService.baseurl}${shop!['shop_photo']}",
                          "Shop Photo",
                        ),

                      if (shop!['owner_shop_photo'] != null)
                        _imageCard(
                          "${apiService.baseurl}${shop!['owner_shop_photo']}",
                          "Owner Photo",
                        ),

                      if (shop!['shop_document'] != null)
                        _imageCard(
                          "${apiService.baseurl}${shop!['shop_document']}",
                          "Shop Document",
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  /// 🔹 REUSABLE INFO CARD
  Widget _infoCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// 🔹 INFO ROW
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "-")),
        ],
      ),
    );
  }

  /// 🔹 IMAGE CARD
  Widget _imageCard(String url, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(imageUrl: url),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.network(
                  url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                /// 🔍 overlay icon
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.zoom_in, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

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
          maxScale: 5,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
