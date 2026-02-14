import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class UpdateCountryScreen extends StatefulWidget {
  final int countryId;
  final String name;
  final String? code;

  const UpdateCountryScreen({
    super.key,
    required this.countryId,
    required this.name,
    this.code,
  });

  @override
  State<UpdateCountryScreen> createState() => _UpdateCountryScreenState();
}

class _UpdateCountryScreenState extends State<UpdateCountryScreen> {
  late TextEditingController nameCtl;
  late TextEditingController codeCtl;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    nameCtl = TextEditingController(text: widget.name);
    codeCtl = TextEditingController(text: widget.code ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.bgred,
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Update Country",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.red.withOpacity(0.5),
              child: const Icon(Icons.public, color: Colors.red, size: 40),
            ),

            const SizedBox(height: 30),

            _field("Country Name", nameCtl),
            const SizedBox(height: 16),
            _field("Country Code", codeCtl, isCodeField: true),

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
                  bool success = await apiService.updateCountry(
                    countryId: widget.countryId,
                    name: nameCtl.text.trim(),
                    code: codeCtl.text.trim(),
                  );

                  if (success) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text(
                  "Update Country Details",
                  style: TextStyle(
                    fontSize: 18,
                    color: ColorConstants.white,
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

  Widget _field(
    String label,
    TextEditingController ctl, {
    bool isCodeField = false,
  }) {
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
          keyboardType: isCodeField ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixText: isCodeField ? "+" : null,
            prefixStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            filled: true,
            fillColor: ColorConstants.textfieldgrey,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: ColorConstants.red,
                width: 1.5,
              ),
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
