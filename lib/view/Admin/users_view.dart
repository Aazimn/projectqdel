import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/model/user_models.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/user_detail.dart';

enum UserTab { approved, pending, rejected }

class UserDirectoryScreen extends StatefulWidget {
  const UserDirectoryScreen({super.key});

  @override
  State<UserDirectoryScreen> createState() => _UserDirectoryScreenState();
}

class _UserDirectoryScreenState extends State<UserDirectoryScreen> {
  final ApiService apiService = ApiService();
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  UserTab currentTab = UserTab.approved;
  List<UserModel> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    users = await apiService.getJoinRequests();
    setState(() => loading = false);
  }

  List<UserModel> get filteredUsers {
    List<UserModel> tabFiltered;

    switch (currentTab) {
      case UserTab.approved:
        tabFiltered = users
            .where((u) => u.approvalStatus == "approved")
            .toList();
        break;
      case UserTab.pending:
        tabFiltered = users
            .where((u) => u.approvalStatus == "pending")
            .toList();
        break;
      case UserTab.rejected:
        tabFiltered = users
            .where((u) => u.approvalStatus == "rejected")
            .toList();
        break;
    }

    if (searchQuery.isEmpty) return tabFiltered;

    return tabFiltered.where((user) {
      final name = "${user.firstName} ${user.lastName}".toLowerCase();
      final email = user.email.toLowerCase();

      return name.contains(searchQuery) ||
          email.contains(searchQuery) ||
          user.id.toString().contains(searchQuery);
    }).toList();
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

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 130,
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
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "USER DETAILS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      body: Column(
        children: [
          _header(context),
          _searchBar(),
          _tabs(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (_, i) {
                      final user = filteredUsers[i];
                      return _unifiedUserCard(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        style: const TextStyle(color: ColorConstants.black),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = "");
                  },
                )
              : null,
          hintText: "Search by name or email",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: ColorConstants.textfieldgrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _tab("APPROVED", UserTab.approved),
            _tab("PENDING", UserTab.pending),
            _tab("DISAPPROVED", UserTab.rejected),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, UserTab tab) {
    final active = currentTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentTab = tab),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? ColorConstants.red : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _openStatusModal(UserModel user, bool initialApprove) {
    bool approveSelected = initialApprove;
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
                  _statusOption(
                    title: "Approve User",
                    subtitle: "Grants access to platform",
                    selected: approveSelected,
                    color: Colors.green,
                    onTap: () => setModalState(() => approveSelected = true),
                  ),

                  const SizedBox(height: 12),

                  _statusOption(
                    title: "Reject User",
                    subtitle: "Deny application",
                    selected: !approveSelected,
                    color: Colors.red,
                    onTap: () => setModalState(() => approveSelected = false),
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

                      final success = await apiService.carrierApproval(
                        userId: user.id,
                        approve: approveSelected,
                      );

                      if (!success) return;

                      setState(() {
                        final index = users.indexWhere((u) => u.id == user.id);
                        if (index != -1) {
                          users[index] = users[index].copyWith(
                            approvalStatus: approveSelected
                                ? "approved"
                                : "rejected",
                          );
                        }

                        currentTab = approveSelected
                            ? UserTab.approved
                            : UserTab.rejected;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            approveSelected
                                ? "User approved successfully"
                                : "User rejected successfully",
                          ),
                          backgroundColor: approveSelected
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                    },
                    child: const Text(
                      "Confirm Changes",
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorConstants.white,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: ColorConstants.white),
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

  Widget _unifiedUserCard(UserModel user) {
    final status = user.approvalStatus.toLowerCase();

    return GestureDetector(
      onTap: () async {
        final updatedStatus = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
        );

        if (updatedStatus != null) {
          fetchUsers();
        }
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: BoxBorder.all(color: ColorConstants.bgred),
        ),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user.firstName} ${user.lastName}".toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "ID: ${user.id}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3.5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: status == "approved"
                          ? Colors.green.withOpacity(.2)
                          : status == "rejected"
                          ? Colors.red.withOpacity(.2)
                          : Colors.orange.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == "approved"
                            ? Colors.green
                            : status == "rejected"
                            ? Colors.red
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (status == "pending") ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _openStatusModal(user, true),
                child: const Text(
                  "APPROVE",
                  style: TextStyle(color: ColorConstants.white),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _openStatusModal(user, false),
                child: const Text(
                  "REJECT",
                  style: TextStyle(color: ColorConstants.white),
                ),
              ),
            ] else if (status == "approved") ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _openStatusModal(user, false),
                child: const Text(
                  "REJECT",
                  style: TextStyle(color: ColorConstants.white),
                ),
              ),
            ] else if (status == "rejected") ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => _openStatusModal(user, true),
                child: const Text(
                  "APPROVE",
                  style: TextStyle(color: ColorConstants.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusOption({
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
            Column(
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
          ],
        ),
      ),
    );
  }
}
