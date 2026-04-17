import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/CommonPages/usertype_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();
  UserModel? user;

  bool loading = true;
  bool updating = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _zipCodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    _zipCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final api = ApiService();
    user = await api.getMyProfile();
    _populateControllers();
    setState(() => loading = false);
  }

  void _populateControllers() {
    if (user == null) return;


    _firstNameCtrl.text = user!.firstName;
    _lastNameCtrl.text = user!.lastName;
    _emailCtrl.text = user!.email;

    if (user!.isShop) {
 
      _shopNameCtrl.text = user!.shopName ?? '';

    
      final address = user!.shopAddress;
      if (address != null) {
        _addressCtrl.text = address['address'] ?? '';
        _landmarkCtrl.text = address['landmark'] ?? '';
        _zipCodeCtrl.text = address['zip_code'] ?? '';
      }
    }
  }

  Future<void> _updateUserRegistration() async {
    setState(() => updating = true);

    bool personalUpdateSuccess = true;
    bool shopUpdateSuccess = true;

   
    if (_firstNameCtrl.text.trim() != user!.firstName ||
        _lastNameCtrl.text.trim() != user!.lastName ||
        _emailCtrl.text.trim() != user!.email) {
      personalUpdateSuccess = await apiService.updateMyProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
    }

    if (user!.isShop) {
      shopUpdateSuccess = await apiService.updateUserrRegistration(
        shopName: _shopNameCtrl.text.trim().isEmpty
            ? null
            : _shopNameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty
            ? null
            : _addressCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim().isEmpty
            ? null
            : _landmarkCtrl.text.trim(),
        zipCode: _zipCodeCtrl.text.trim().isEmpty
            ? null
            : _zipCodeCtrl.text.trim(),
      );
    }

    setState(() => updating = false);

    if (personalUpdateSuccess && shopUpdateSuccess) {
     
      setState(() {
        user = user!.copyWith(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          shopName: _shopNameCtrl.text.trim(),
        );
        if (user!.shopAddress != null) {
          user!.shopAddress!['address'] = _addressCtrl.text.trim();
          user!.shopAddress!['landmark'] = _landmarkCtrl.text.trim();
          user!.shopAddress!['zip_code'] = _zipCodeCtrl.text.trim();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update profile. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _header(context),
                  const SizedBox(height: 60),
                  _profileInfo(),
                  const SizedBox(height: 10),
                  _personalDetailsCard(),
                  if (user?.isShop == true) ...[
                    const SizedBox(height: 20),
                    _shopAddressCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            color: ColorConstants.red,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Positioned(
          top: 45,
          left: 16,
          child: _circleButton(
            Icons.arrow_back_ios_new,
            () => Navigator.pop(context),
          ),
        ),
        Positioned(
          bottom: -50,
          left: 0,
          right: 0,
          child: Center(
            child: Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: user?.isShop == true
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                  ),
                  child: Icon(
                    user?.isShop == true ? Icons.store : Icons.person,
                    size: 50,
                    color: user?.isShop == true
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: user?.isApproved == true
                          ? Colors.green
                          : Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      user?.isApproved == true ? Icons.check : Icons.pending,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: ColorConstants.red, size: 18),
      ),
    );
  }

  Widget _profileInfo() {
    final name = user?.displayName ?? "GUEST USER";

    return Column(
      children: [
        Text(
          name.toUpperCase(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: user?.isShop == true
                ? Colors.blue.shade50
                : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user?.isShop == true ? Icons.store : Icons.local_shipping,
                size: 14,
                color: user?.isShop == true
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                user?.userTypeDisplay ?? "USER",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: user?.isShop == true
                      ? Colors.blue.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personalDetailsCard() {
    return _card(
      title: "Personal Details",
      leading: const Icon(Icons.person, color: ColorConstants.red),
      children: [
        _divider(),
        _infoRow(
          Icons.badge,
          "FULL NAME",
          user?.displayName.toUpperCase() ?? "--",
        ),
        _divider(),
        _infoRow(Icons.email, "EMAIL ADDRESS", user?.email ?? "--"),
        _divider(),
        _infoRow(Icons.phone, "PHONE NUMBER", user?.phone ?? "--"),
        if (user?.locationDisplay != "Location not set") ...[
          _divider(),
          _infoRow(
            Icons.location_on,
            "LOCATION",
            user?.locationDisplay ?? "--",
          ),
        ],
        const SizedBox(height: 12),
        _divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionBtn("Change User Type", ColorConstants.red, () async {
              if (user != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsertypeScreen(currentUser: user!),
                  ),
                );
                loadProfile();
              }
            }),
            const SizedBox(width: 20),
            _actionBtn("Edit Profile", ColorConstants.red, _openEditDialog),
          ],
        ),
      ],
    );
  }

  Widget _shopAddressCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _card(
        title: "Shop Information",
        leading: const Icon(Icons.store, color: Colors.red),
        children: [
          _divider(),
          _infoRow(Icons.storefront, "SHOP NAME", user?.shopName ?? "--"),
          _divider(),
          _infoRow(
            Icons.location_city,
            "ADDRESS",
            user?.shopAddressDisplay ?? "--",
          ),
          if (user?.shopAddress != null) ...[
            if (user!.shopAddress!['landmark'] != null &&
                user!.shopAddress!['landmark'].toString().isNotEmpty)
              _divider(),
            if (user!.shopAddress!['landmark'] != null &&
                user!.shopAddress!['landmark'].toString().isNotEmpty)
              _infoRow(
                Icons.landscape,
                "LANDMARK",
                user!.shopAddress!['landmark'].toString(),
              ),
            if (user!.shopAddress!['zip_code'] != null &&
                user!.shopAddress!['zip_code'].toString().isNotEmpty)
              _divider(),
            if (user!.shopAddress!['zip_code'] != null &&
                user!.shopAddress!['zip_code'].toString().isNotEmpty)
              _infoRow(
                Icons.pin_drop,
                "ZIP CODE",
                user!.shopAddress!['zip_code'].toString(),
              ),
            if (user!.shopAddress!['district'] != null &&
                user!.shopAddress!['district'].toString().isNotEmpty)
              _divider(),
            if (user!.shopAddress!['district'] != null &&
                user!.shopAddress!['district'].toString().isNotEmpty)
              _infoRow(
                Icons.map,
                "DISTRICT",
                user!.shopAddress!['district'].toString(),
              ),
            if (user!.shopAddress!['state'] != null &&
                user!.shopAddress!['state'].toString().isNotEmpty)
              _divider(),
            if (user!.shopAddress!['state'] != null &&
                user!.shopAddress!['state'].toString().isNotEmpty)
              _infoRow(
                Icons.location_city,
                "STATE",
                user!.shopAddress!['state'].toString(),
              ),
            if (user!.shopAddress!['country'] != null &&
                user!.shopAddress!['country'].toString().isNotEmpty)
              _divider(),
            if (user!.shopAddress!['country'] != null &&
                user!.shopAddress!['country'].toString().isNotEmpty)
              _infoRow(
                Icons.public,
                "COUNTRY",
                user!.shopAddress!['country'].toString(),
              ),
          ],
        ],
      ),
    );
  }

  void _openEditDialog() {
    if (user == null) return;

    
    _firstNameCtrl.text = user!.firstName;
    _lastNameCtrl.text = user!.lastName;
    _emailCtrl.text = user!.email;

    if (user!.isShop) {
      _shopNameCtrl.text = user!.shopName ?? '';
      final address = user!.shopAddress;
      if (address != null) {
        _addressCtrl.text = address['address'] ?? '';
        _landmarkCtrl.text = address['landmark'] ?? '';
        _zipCodeCtrl.text = address['zip_code'] ?? '';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
           
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ColorConstants.red, Color(0xffE53935)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.edit_note,
                            color: ColorConstants.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Edit Profile",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Update your personal information",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                 
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                         
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: ColorConstants.red,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Personal Details",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _modernTextField(
                            controller: _firstNameCtrl,
                            label: "First Name",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _modernTextField(
                            controller: _lastNameCtrl,
                            label: "Last Name",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _modernTextField(
                            controller: _emailCtrl,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          if (user?.isShop == true) ...[
                            const SizedBox(height: 24),
                     
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.store_outlined,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Shop Information",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _modernTextField(
                              controller: _shopNameCtrl,
                              label: "Shop Name",
                              icon: Icons.store_outlined,
                            ),
                            const SizedBox(height: 12),
                            _modernTextField(
                              controller: _addressCtrl,
                              label: "Address",
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 12),
                            _modernTextField(
                              controller: _landmarkCtrl,
                              label: "Landmark",
                              icon: Icons.landslide,
                            ),
                            const SizedBox(height: 12),
                            _modernTextField(
                              controller: _zipCodeCtrl,
                              label: "Zip Code",
                              icon: Icons.pin_drop_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          const SizedBox(height: 32),
                         
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: updating
                                      ? null
                                      : () async {
                                          Navigator.pop(context);
                                          await _updateUserRegistration();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: updating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Save Changes",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _modernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: ColorConstants.red, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    Widget? leading,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.grey),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (leading != null) leading,
              if (leading != null) const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      width: double.infinity,
      color: Colors.grey.shade300,
    );
  }
}
