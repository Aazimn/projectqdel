import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/add_district.dart';
import 'package:projectqdel/view/Admin/update_district.dart';

class DistrictScreen extends StatefulWidget {
  final int stateId;
  final String stateName;
  const DistrictScreen({
    super.key,
    required this.stateId,
    required this.stateName,
  });

  @override
  State<DistrictScreen> createState() => _DistrictScreenState();
}

class _DistrictScreenState extends State<DistrictScreen> {
  TextEditingController districtctl = TextEditingController();

  ApiService apiService = ApiService();
  late Future<List<dynamic>> districtfuture;
  TextEditingController searchController = TextEditingController();
  String searchText = '';

  @override
  void initState() {
    super.initState();
    districtfuture = apiService.getDistricts(stateId: widget.stateId);
  }

  @override
  void dispose() {
    super.dispose();
    searchController.dispose();
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
              "Manage Districts",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorConstants.red,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDistrictScreen(
                stateId: widget.stateId,
                stateName: widget.stateName,
              ),
            ),
          );

          if (result == true) {
            setState(() {
              districtfuture = apiService.getDistricts(stateId: widget.stateId);
            });
          }
        },
        child: const Text("Add"),
      ),
      body: Column(
        children: [
          _header(context),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search district...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: ColorConstants.textfieldgrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: districtfuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("No districts added yet"));
                }

                final stateFiltered = snapshot.data!
                    .where((d) => d['state'] == widget.stateId)
                    .toList();

                final filteredDistricts = stateFiltered.where((d) {
                  return d['name'].toString().toLowerCase().contains(
                    searchText,
                  );
                }).toList();

                if (filteredDistricts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No districts found",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.white,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDistricts.length,
                  itemBuilder: (context, index) {
                    return districtCard(district: filteredDistricts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget districtCard({required Map district}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ColorConstants.bgred),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorConstants.red.withOpacity(0.12),

                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_city, color: Colors.red, size: 22),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        district['name'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "State: ${widget.stateName}",
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorConstants.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.stateName,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Divider(color: Colors.grey.shade200),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UpdateDistrictScreen(
                            districtId: district['id'],
                            districtName: district['name'],
                            stateId: widget.stateId,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          districtfuture = apiService.getDistricts(
                            stateId: widget.stateId,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Update"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.green,
                      side: BorderSide(color: ColorConstants.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await apiService.deleteDistrict(
                        districtId: district['id'],
                      );
                      setState(() {
                        districtfuture = apiService.getDistricts(
                          stateId: widget.stateId,
                        );
                      });
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("Delete"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
