import 'package:flutter/material.dart';
import 'package:logger/logger.dart'; // Make sure you have this
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
  final Logger logger = Logger();
  late UserModel user;
  late String baseUrl; // Add this
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    baseUrl = apiService.baseurl; // Get base URL from ApiService
    _logDocumentInfo();
  }

  String _getFullDocumentUrl() {
    if (user.document == null || user.document!.isEmpty) {
      return '';
    }

    // If it's already a full URL, return as is
    if (user.document!.startsWith('http')) {
      return user.document!;
    }

    // Remove leading slash if present to avoid double slashes
    String documentPath = user.document!.startsWith('/')
        ? user.document!.substring(1)
        : user.document!;

    // Ensure baseUrl doesn't end with slash
    String base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return '$base/$documentPath';
  }

  void _logDocumentInfo() {
    logger.i("=== DOCUMENT DEBUG INFO ===");
    logger.i("User ID: ${user.id}");
    logger.i("User Name: ${user.firstName} ${user.lastName}");
    logger.i("Original Document URL: ${user.document}");
    logger.i("Document exists: ${user.document != null}");
    logger.i("Document is empty: ${user.document?.isEmpty ?? true}");

    if (user.document != null && user.document!.isNotEmpty) {
      logger.i("Document URL length: ${user.document!.length}");
      logger.i(
        "Document URL starts with http: ${user.document!.startsWith('http')}",
      );
      logger.i(
        "Document URL contains 'media': ${user.document!.contains('media')}",
      );

      // Log the full URL we'll use
      String fullUrl = _getFullDocumentUrl();
      logger.i("Full document URL: $fullUrl");
    }
  }

  Future<void> _updateApproval(String newStatus) async {
    setState(() => isUpdating = true);

    final success = await apiService.updateUserStatus(
      userId: user.id,
      status: newStatus,
    );

    setState(() => isUpdating = false);

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update user status"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        user = user.copyWith(approvalStatus: newStatus);
      });

      Navigator.pop(context, user.approvalStatus);

      String message;
      Color color;
      switch (newStatus) {
        case "approved":
          message = "User Approved Successfully";
          color = Colors.green;
          break;
        case "rejected":
          message = "User Rejected Successfully";
          color = Colors.red;
          break;
        default:
          message = "User status updated to Pending";
          color = Colors.orange;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  void _openStatusModal() {
    String selectedStatus = user.approvalStatus.toLowerCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Update User Status",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildStatusOption(
                    title: "Approve User",
                    subtitle: "Grants access to platform",
                    selected: selectedStatus == "approved",
                    color: Colors.green,
                    onTap: () =>
                        setModalState(() => selectedStatus = "approved"),
                  ),
                  const SizedBox(height: 12),

                  _buildStatusOption(
                    title: "Reject User",
                    subtitle: "Deny application",
                    selected: selectedStatus == "rejected",
                    color: Colors.red,
                    onTap: () =>
                        setModalState(() => selectedStatus = "rejected"),
                  ),
                  const SizedBox(height: 12),

                  _buildStatusOption(
                    title: "Set as Pending",
                    subtitle: "Move back to pending review",
                    selected: selectedStatus == "pending",
                    color: Colors.orange,
                    onTap: () =>
                        setModalState(() => selectedStatus = "pending"),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _updateApproval(selectedStatus);
                    },
                    child: const Text(
                      "Confirm Changes",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
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

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.15) : Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 60)),
              SliverToBoxAdapter(child: _profileInfo()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _personalDetailsCard()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _documentCard(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _approvalCard()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
            ],
          ),
          if (isUpdating)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
          child: _circleButton(Icons.edit, _openStatusModal),
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
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: 16,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
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
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.approvalStatus.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
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

  Widget _documentCard(BuildContext context) {
    // Check if document exists
    if (user.document == null || user.document!.isEmpty) {
      logger.w("No document available for user ${user.id}");
      return _card(
        title: "Uploaded Document",
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "No document uploaded",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    String fullDocumentUrl = _getFullDocumentUrl();
    logger.i("Attempting to load document: $fullDocumentUrl");

    return _card(
      title: "Uploaded Document",
      children: [
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _openDocumentPreview(context, fullDocumentUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  fullDocumentUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      logger.i(
                        "Document loaded successfully: $fullDocumentUrl",
                      );
                      return child;
                    }
                    logger.d(
                      "Loading document: ${progress.cumulativeBytesLoaded}/${progress.expectedTotalBytes}",
                    );
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, error, stackTrace) {
                    logger.e("Failed to load document: $error");
                    logger.e("Document URL: $fullDocumentUrl");
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Failed to load document",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullDocumentUrl,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openDocumentPreview(BuildContext context, String documentUrl) {
    logger.i("Opening document preview: $documentUrl");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              "Document Preview",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                documentUrl,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, error, __) {
                  logger.e("Failed to load document in preview: $error");
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load document",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        documentUrl,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _approvalCard() {
    return _card(
      title: "Approval Actions",
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor(), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.approvalStatus.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getStatusSubtitle(),
                      style: TextStyle(color: _getStatusColor()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildApprovalButtons(),
      ],
    );
  }

  Widget _buildApprovalButtons() {
    final status = user.approvalStatus.toLowerCase();

    if (status == "pending") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  "Approve",
                  Colors.green,
                  () => _updateApproval("approved"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  "Reject",
                  Colors.red,
                  () => _updateApproval("rejected"),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == "approved") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  "Reject",
                  Colors.red,
                  () => _updateApproval("rejected"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  "Set as Pending",
                  Colors.orange,
                  () => _updateApproval("pending"),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (status == "rejected") {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  "Approve",
                  Colors.green,
                  () => _updateApproval("approved"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  "Set as Pending",
                  Colors.orange,
                  () => _updateApproval("pending"),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: isUpdating ? null : onTap,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Color _getStatusColor() {
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  String _getStatusSubtitle() {
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        return 'Verified and approved';
      case 'rejected':
        return 'Application rejected';
      case 'pending':
        return 'Awaiting review';
      default:
        return '';
    }
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 1,
      color: Colors.grey.shade300,
    );
  }
}
