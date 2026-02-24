import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:lottie/lottie.dart';

class OrderPlacedScreen extends StatefulWidget {
  final int productId;
  final int senderAddressId;
  final int receiverAddressId;
  const OrderPlacedScreen({
    super.key,
    required this.productId,
    required this.senderAddressId,
    required this.receiverAddressId,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? product;
  bool loading = true;
  bool showSuccessAnimation = true;
  int? id;
  Map<String, dynamic>? senderAddress;
  Map<String, dynamic>? receiverAddress;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController volumeCtrl = TextEditingController();

  final TextEditingController senderNameCtrl = TextEditingController();
  final TextEditingController senderPhoneCtrl = TextEditingController();
  final TextEditingController senderAddressCtrl = TextEditingController();
  final TextEditingController senderLandmarkCtrl = TextEditingController();
  final TextEditingController senderDistrictCtrl = TextEditingController();
  final TextEditingController senderStateCtrl = TextEditingController();
  final TextEditingController senderCountryCtrl = TextEditingController();
  final TextEditingController senderZipCtrl = TextEditingController();

  final TextEditingController receiverNameCtrl = TextEditingController();
  final TextEditingController receiverPhoneCtrl = TextEditingController();
  final TextEditingController receiverAddressCtrl = TextEditingController();
  final TextEditingController receiverLandmarkCtrl = TextEditingController();
  final TextEditingController receiverDistrictCtrl = TextEditingController();
  final TextEditingController receiverStateCtrl = TextEditingController();
  final TextEditingController receiverCountryCtrl = TextEditingController();
  final TextEditingController receiverZipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  void _fillControllers() {
    nameCtrl.text = product?['name'] ?? '';
    descCtrl.text = product?['description'] ?? '';
    weightCtrl.text = product?['actual_weight']?.toString() ?? '';
    volumeCtrl.text = product?['volume']?.toString() ?? '';
  }

  Future<void> _startFlow() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      showSuccessAnimation = false;
    });

    await Future.wait([
      _loadProduct(),
      _loadSenderAddress(),
      _loadReceiverAddress(),
    ]);
  }

  Future<void> _loadSenderAddress() async {
    final data = await apiService.getSenderAddressById(widget.senderAddressId);

    if (!mounted || data == null) return;

    setState(() {
      senderAddress = data;
    });

    senderNameCtrl.text = data['sender_name'] ?? '';
    senderPhoneCtrl.text = data['phone_number'] ?? '';
    senderAddressCtrl.text = data['address'] ?? '';
    senderLandmarkCtrl.text = data['landmark'] ?? '';
    senderDistrictCtrl.text = data['district']?.toString() ?? '';
    senderStateCtrl.text = data['state']?.toString() ?? '';
    senderCountryCtrl.text = data['country']?.toString() ?? '';
    senderZipCtrl.text = data['zip_code'] ?? '';
  }

  Future<void> _loadReceiverAddress() async {
    try {
      final data = await apiService.getReceiverAddressByPickupId(
        widget.receiverAddressId,
      );

      if (!mounted) return;

      setState(() {
        receiverAddress = data!['data'];
      });

      receiverNameCtrl.text = receiverAddress?['receiver_name'] ?? '';
      receiverPhoneCtrl.text = receiverAddress?['receiver_phone'] ?? '';
      receiverAddressCtrl.text = receiverAddress?['address_text'] ?? '';
      receiverLandmarkCtrl.text = receiverAddress?['landmark'] ?? '';
      receiverDistrictCtrl.text =
          receiverAddress?['district']?.toString() ?? '';
      receiverStateCtrl.text = receiverAddress?['state']?.toString() ?? '';
      receiverCountryCtrl.text = receiverAddress?['country']?.toString() ?? '';
      receiverZipCtrl.text = receiverAddress?['zip_code'] ?? '';
    } catch (e) {
      if (!mounted) return;
      debugPrint("Receiver address error: $e");
    }
  }

  Widget _successLottie() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/lottie_assets/successful.json', repeat: false),
          const SizedBox(height: 20),
          const Text(
            "Order Placed Successfully!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProduct() async {
    try {
      final data = await apiService.getProductById(widget.productId);

      if (!mounted) return;

      if (data == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load product")));
      }

      setState(() {
        product = data;
        loading = false;
      });
      _fillControllers();
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _orderPlacedContent() {
    return Column(
      children: [
        _header(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _searchingCard(),
                const SizedBox(height: 16),
                _orderSummary(),
                const SizedBox(height: 16),
                _detailsCard(
                  title: "SENDER DETAILS",
                  name: senderAddress?['sender_name'] ?? "—",
                  phone: senderAddress?['phone_number'] ?? "—",
                  address: senderAddress?['address'] ?? "—",
                  landmark: senderAddress?['landmark'],
                  district: senderAddress?['district']?.toString(),
                  state: senderAddress?['state']?.toString(),
                  country: senderAddress?['country']?.toString(),
                  zip: senderAddress?['zip_code'],
                  onEdit: _openEditSenderSheet,
                ),
                const SizedBox(height: 16),
                _detailsCard(
                  title: "RECEIVER DETAILS",
                  name: receiverAddress?['receiver_name'] ?? "—",
                  phone: receiverAddress?['receiver_phone'] ?? "—",
                  address: receiverAddress?['address_text'] ?? "—",
                  landmark: receiverAddress?['landmark'],
                  district: receiverAddress?['district']?.toString(),
                  state: receiverAddress?['state']?.toString(),
                  country: receiverAddress?['country']?.toString(),
                  zip: receiverAddress?['zip_code'],
                  onEdit: _openEditReceiverSheet,
                ),
                const SizedBox(height: 16),
                _cancelOrderSection(context),
              ],
            ),
          ),
        ),
        _bottomButton(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: showSuccessAnimation
            ? _successLottie()
            : loading
            ? const Center(child: CircularProgressIndicator())
            : _orderPlacedContent(),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: const [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.check, color: Color(0xFFE53935), size: 32),
          ),
          SizedBox(height: 12),
          Text(
            "Order Placed Successfully!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Order ID: #SHP-92834012",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _searchingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Text(
                      "Searching for Delivery Partner",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 6),
                    _LiveDot(),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  "We’re finding the nearest available rider for you",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order summery".toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _productImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (product?['name'] ?? '').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      (product?['description'] ?? '').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "🔒 ${product?['actual_weight']} kg   📦 ${product?['volume']} cm³",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _openEditProductSheet();
            },
            icon: const Icon(Icons.edit, color: Colors.red),
            label: const Text(
              "Edit Order",
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEditProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Product",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _textField("Product Name", nameCtrl),
              _textField("Description", descCtrl),
              _textField("Weight (kg)", weightCtrl, isNumber: true),
              _textField("Volume (cm³)", volumeCtrl, isNumber: true),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Update Product"),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _updateProduct() async {
    Navigator.pop(context); // close bottom sheet

    final success = await apiService.updateProduct(
      productId: widget.productId,
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
      actualWeight: weightCtrl.text.trim(),
      volume: volumeCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await _loadProduct(); // refresh UI

      // ✅ clear old snackbars + show new one
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Product updated successfully"),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Failed to update product")),
        );
    }
  }

  Widget _detailsCard({
    required String title,
    required String name,
    required String phone,
    required String address,
    String? landmark,
    String? district,
    String? state,
    String? country,
    String? zip,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: onEdit,
                child: Icon(Icons.edit, color: Colors.red, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(phone),
          const SizedBox(height: 8),
          Text(
            address.toUpperCase(),
            style: const TextStyle(color: Colors.grey),
          ),
          if (district != null) Text("District: $district"),
          if (state != null) Text("State: $state"),
          if (country != null) Text("Country: $country"),
          if (zip != null) Text("Zip: $zip"),
          if (landmark != null) ...[
            const SizedBox(height: 6),
            Text(
              landmark.toUpperCase(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void _openEditReceiverSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Receiver Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _textField("Receiver Name", receiverNameCtrl),
                _textField("Phone", receiverPhoneCtrl, isNumber: true),
                _textField("Address", receiverAddressCtrl),
                _textField("Landmark", receiverLandmarkCtrl),
                _textField("District ID", receiverDistrictCtrl, isNumber: true),
                _textField("State ID", receiverStateCtrl, isNumber: true),
                _textField("Country ID", receiverCountryCtrl, isNumber: true),
                _textField("Zip Code", receiverZipCtrl),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateReceiverAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Update Address"),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateReceiverAddress() async {
    Navigator.pop(context);

    final success = await apiService.updateReceiverAddress(
      addressId: widget.receiverAddressId,
      productId: receiverAddress?['product'], // 🔥 REQUIRED
      receiverId: receiverAddress?['receiver'],

      receiverName: receiverNameCtrl.text.trim().isEmpty
          ? (receiverAddress?['receiver_name'] ?? "").toString()
          : receiverNameCtrl.text.trim(),

      phoneNumber: receiverPhoneCtrl.text.trim().isEmpty
          ? (receiverAddress?['receiver_phone'] ?? "").toString()
          : receiverPhoneCtrl.text.trim(),

      address: receiverAddressCtrl.text.trim().isEmpty
          ? (receiverAddress?['address_text'] ?? "").toString()
          : receiverAddressCtrl.text.trim(),

      landmark: receiverLandmarkCtrl.text.trim().isEmpty
          ? (receiverAddress?['landmark'] ?? "").toString()
          : receiverLandmarkCtrl.text.trim(),

      district: receiverDistrictCtrl.text.trim().isEmpty
          ? int.tryParse(receiverAddress?['district']?.toString() ?? '')
          : int.tryParse(receiverDistrictCtrl.text.trim()),

      state: receiverStateCtrl.text.trim().isEmpty
          ? int.tryParse(receiverAddress?['state']?.toString() ?? '')
          : int.tryParse(receiverStateCtrl.text.trim()),

      country: receiverCountryCtrl.text.trim().isEmpty
          ? int.tryParse(receiverAddress?['country']?.toString() ?? '')
          : int.tryParse(receiverCountryCtrl.text.trim()),

      zipCode: receiverZipCtrl.text.trim().isEmpty
          ? (receiverAddress?['zip_code'] ?? "").toString()
          : receiverZipCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await _loadReceiverAddress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Receiver updated successfully")),
      );
    }
  }

  void _openEditSenderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Sender Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _textField("Sender Name", senderNameCtrl),
                _textField("Phone Number", senderPhoneCtrl, isNumber: true),
                _textField("Address", senderAddressCtrl),
                _textField("Landmark", senderLandmarkCtrl),
                _textField("District ID", senderDistrictCtrl, isNumber: true),
                _textField("State ID", senderStateCtrl, isNumber: true),
                _textField("Country ID", senderCountryCtrl, isNumber: true),
                _textField("Zip Code", senderZipCtrl),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateSenderAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Update Address"),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateSenderAddress() async {
    Navigator.pop(context);

    final success = await apiService.updateSenderAddress(
      addressId: widget.senderAddressId,

      senderName: senderNameCtrl.text.trim().isEmpty
          ? (senderAddress?['sender_name'] ?? "").toString()
          : senderNameCtrl.text.trim(),

      phoneNumber: senderPhoneCtrl.text.trim().isEmpty
          ? (senderAddress?['phone_number'] ?? "").toString()
          : senderPhoneCtrl.text.trim(),

      address: senderAddressCtrl.text.trim().isEmpty
          ? (senderAddress?['address'] ?? "").toString()
          : senderAddressCtrl.text.trim(),

      landmark: senderLandmarkCtrl.text.trim().isEmpty
          ? (senderAddress?['landmark'] ?? "").toString()
          : senderLandmarkCtrl.text.trim(),

      district: senderDistrictCtrl.text.trim().isEmpty
          ? (senderAddress?['district'] ?? "")
          : senderDistrictCtrl.text.trim(),

      state: senderStateCtrl.text.trim().isEmpty
          ? (senderAddress?['state'] ?? "")
          : senderStateCtrl.text.trim(),

      country: senderCountryCtrl.text.trim().isEmpty
          ? (senderAddress?['country'] ?? "")
          : senderCountryCtrl.text.trim(),

      zipCode: senderZipCtrl.text.trim().isEmpty
          ? (senderAddress?['zip_code'] ?? "").toString()
          : senderZipCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await _loadSenderAddress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sender updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update sender address")),
      );
    }
  }

  Widget _bottomButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.list, color: ColorConstants.white),
        label: const Text(
          "Go to My Orders",
          style: TextStyle(color: ColorConstants.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 187, 27, 27),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: BoxBorder.all(color: ColorConstants.bgred),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _cancelOrderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: OutlinedButton.icon(
        onPressed: () {
          _showCancelDialog(context);
        },
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        label: const Text(
          "Cancel Order",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _productImage() {
    if (product == null) {
      return const Icon(Icons.inventory_2, color: Colors.grey);
    }

    final images = product!['images'];

    if (images == null || images.isEmpty) {
      return const Icon(Icons.inventory_2, color: Colors.grey);
    }

    final imagePath = images[0]['image'];

    if (imagePath == null || imagePath.isEmpty) {
      return const Icon(Icons.inventory_2, color: Colors.grey);
    }

    final imageUrl = "${apiService.baseurl}$imagePath";

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.grey);
        },
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.circle, color: Colors.red, size: 8),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
