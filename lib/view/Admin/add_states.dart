import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class AddStateScreen extends StatefulWidget {
  final int countryId;
  final String countryName;

  const AddStateScreen({
    super.key,
    required this.countryId,
    required this.countryName,
  });

  @override
  State<AddStateScreen> createState() => _AddStateScreenState();
}

class _AddStateScreenState extends State<AddStateScreen> {
  final TextEditingController stateCtl = TextEditingController();
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bgred,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        title: Center(
          child: Text(
            "Add State",
            style: TextStyle(
              color: ColorConstants.white,
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
              child: const Icon(Icons.location_on, size: 40, color: Colors.red),
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

                  final success = await apiService.addstates(
                    name: stateCtl.text.trim(),
                    country: widget.countryId,
                  );

                  if (success) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  "Save State",
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
