import 'package:flutter/material.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final ApiService apiService = ApiService();
  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  Future<void> _updateApproval(bool approve) async {
    final success = await apiService.carrierApproval(
      userId: user.id,
      approve: approve,
    );

    if (!success) return;

    setState(() {
      user = user.copyWith(approvalStatus: approve ? "approved" : "rejected");
    });

    Navigator.pop(context, user.approvalStatus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? "User Approved Successfully" : "User Rejected"),
        backgroundColor: approve ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 20),
                  _personalDetailsCard(),
                  const SizedBox(height: 20),
                  if (user.document != null && user.document!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _documentCard(context),
                    const SizedBox(height: 20),
                    _approvalCard(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _approvalActions() {
  //   final status = user.approvalStatus.toLowerCase();

  //   if (status == "approved") {
  //     return _actionBtn("Reject User", Colors.red, () {
  //       _updateApproval(false);
  //     });
  //   }

  //   if (status == "rejected") {
  //     return _actionBtn("Approve User", Colors.green, () {
  //       _updateApproval(true);
  //     });
  //   }

  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _actionBtn("Approve", Colors.green, () {
  //           _updateApproval(true);
  //         }),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: _actionBtn("Reject", Colors.red, () {
  //           _updateApproval(false);
  //         }),
  //       ),
  //     ],
  //   );
  // }

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

  void _openDocumentPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(child: Image.network(user.document!)),
          ),
        ),
      ),
    );
  }

  Widget _documentCard(BuildContext context) {
    return _card(
      title: "Uploaded Document",
      children: [
        GestureDetector(
          onTap: () => _openDocumentPreview(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              user.document!,

              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 180,
                  alignment: Alignment.center,
                  child: const Text("Failed to load document"),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Tap to view full image",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget documentWidget(UserModel user) {
    if (user.document == null || user.document!.isEmpty) {
      return const Text(
        "No document uploaded",
        style: TextStyle(color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        user.document!,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Text("Failed to load document");
        },
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
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
          top: 45,
          right: 16,
          child: _circleButton(Icons.more_horiz, () {}),
        ),
        const Positioned(
          top: 48,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Profile Details",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    color: Colors.orange.shade100,
                  ),
                  child: const Icon(Icons.person, size: 50),
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
        child: Icon(icon, color: Colors.red, size: 18),
      ),
    );
  }

  Widget _profileInfo() {
    return Column(
      children: [
        Text(
          "${user.firstName} ${user.lastName}".toUpperCase(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _personalDetailsCard() {
    return _card(
      title: "Personal Details",
      children: [
        _divider(),
        _infoRow(
          Icons.badge,
          "FULL NAME",
          "${user.firstName} ${user.lastName}".toUpperCase(),
        ),
        _divider(),

        _infoRow(Icons.fingerprint, "USER ID", "ID-${user.id}"),
        _divider(),

        _infoRow(Icons.email, "EMAIL ADDRESS", user.email),
        _divider(),

        _infoRow(Icons.phone, "PHONE NUMBER", user.phone),
      ],
    );
  }

  Color get approvalColor {
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get approvalIcon {
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_top;
      default:
        return Icons.info;
    }
  }

  String get approvalSubtitle {
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Approval';
      default:
        return '';
    }
  }

  Widget _approvalCard() {
    final status = user.approvalStatus.toLowerCase();

    return _card(
      title: "Approval Status",
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: approvalColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(approvalIcon, color: approvalColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.approvalStatus.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: approvalColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      approvalSubtitle,
                      style: TextStyle(color: approvalColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (status == "pending")
          Row(
            children: [
              Expanded(
                child: _actionBtn("Approve", Colors.green, () {
                  _updateApproval(true);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn("Reject", Colors.red, () {
                  _updateApproval(false);
                }),
              ),
            ],
          )
        else if (status == "approved")
          _actionBtn("Reject User", Colors.red, () {
            _updateApproval(false);
          })
        else if (status == "rejected")
          _actionBtn("Approve User", Colors.green, () {
            _updateApproval(true);
          }),
      ],
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
        border: BoxBorder.all(color: Colors.red),
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
