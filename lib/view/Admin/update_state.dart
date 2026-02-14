import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class UpdateStateScreen extends StatefulWidget {
  final int stateId;
  final String stateName;
  final int countryId;

  const UpdateStateScreen({
    super.key,
    required this.stateId,
    required this.stateName,
    required this.countryId,
  });

  @override
  State<UpdateStateScreen> createState() => _UpdateStateScreenState();
}

class _UpdateStateScreenState extends State<UpdateStateScreen> {
  late TextEditingController stateCtl;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    stateCtl = TextEditingController(text: widget.stateName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bgred,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        title: const Center(
          child: Text(
            "Update State",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.only(right: 20),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.red.withOpacity(0.4),
              child: const Icon(Icons.edit_location, size: 40, color: Colors.red),
            ),

            const SizedBox(height: 30),

            _field("State Name", stateCtl),

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
                  if (stateCtl.text.trim().isEmpty) return;

                  final success = await apiService.updateState(
                    stateId: widget.stateId,
                    name: stateCtl.text.trim(),
                    countryId: widget.countryId,
                  );

                  if (success) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  "Update State",
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
              borderSide: const BorderSide(color: ColorConstants.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
