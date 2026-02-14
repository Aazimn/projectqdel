import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class UpdateDistrictScreen extends StatefulWidget {
  final int districtId;
  final String districtName;
  final int stateId;

  const UpdateDistrictScreen({
    super.key,
    required this.districtId,
    required this.districtName,
    required this.stateId,
  });

  @override
  State<UpdateDistrictScreen> createState() => _UpdateDistrictScreenState();
}

class _UpdateDistrictScreenState extends State<UpdateDistrictScreen> {
  late TextEditingController districtCtl;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    districtCtl = TextEditingController(text: widget.districtName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bgred,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        title: const Center(
          child: Text(
            "Update District",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 20),
        actions: const [
          Text(
            "QDEL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.red.withOpacity(0.4),
              child: const Icon(
                Icons.edit_location_alt,
                size: 40,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 30),

            _field("District Name", districtCtl),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  if (districtCtl.text.trim().isEmpty) return;

                  final success = await apiService.updateDistrict(
                    districtId: widget.districtId,
                    name: districtCtl.text.trim(),
                    stateId: widget.stateId,
                  );

                  if (success) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  "Update District",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ColorConstants.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctl,
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorConstants.textfieldgrey,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: ColorConstants.red),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: ColorConstants.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
