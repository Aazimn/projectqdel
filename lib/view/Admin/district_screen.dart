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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bgred,
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

      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "Districts of ${widget.stateName}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),

        actions: [
          Text(
            "QDEL",
            style: TextStyle(
              color: ColorConstants.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        actionsPadding: EdgeInsets.only(right: 20),
      ),
      body: Column(
        children: [
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
                fillColor: Colors.white,
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
    final bool isActive = district['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isActive
                ? Colors.red.withOpacity(0.15)
                : Colors.grey.shade300,
            child: Icon(
              Icons.location_city,
              color: isActive ? Colors.red : Colors.grey,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  district['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "State : ${widget.stateName}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
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
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () async {
                  await apiService.deleteDistrict(districtId: district['id']);
                  setState(() {
                    districtfuture = apiService.getDistricts(
                      stateId: widget.stateId,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
