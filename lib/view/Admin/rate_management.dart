
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:projectqdel/services/api_service.dart';

class AdminRateManagement extends StatefulWidget {
  const AdminRateManagement({super.key});

  @override
  State<AdminRateManagement> createState() => _AdminRateManagementState();
}

class _AdminRateManagementState extends State<AdminRateManagement> {
  final Logger logger = Logger();
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minDistanceController = TextEditingController();
  final TextEditingController _maxDistanceController = TextEditingController();
  final TextEditingController _minWeightController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _baseChargeController = TextEditingController();
  final TextEditingController _ratePerKmController = TextEditingController();
  final TextEditingController _ratePerKgController = TextEditingController();
  final TextEditingController _minimumChargeController =
      TextEditingController();
  final TextEditingController _carrierPercentageController =
      TextEditingController();
  final TextEditingController _shopPercentageController =
      TextEditingController();
  final TextEditingController _adminPercentageController =
      TextEditingController();
  final TextEditingController _priorityController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isNameNull = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minDistanceController.dispose();
    _maxDistanceController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    _baseChargeController.dispose();
    _ratePerKmController.dispose();
    _ratePerKgController.dispose();
    _minimumChargeController.dispose();
    _carrierPercentageController.dispose();
    _shopPercentageController.dispose();
    _adminPercentageController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _createRateCard() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _apiService.createRateCard(
          name: _isNameNull
              ? null
              : (_nameController.text.isNotEmpty ? _nameController.text : null),
          minDistanceKm: double.parse(_minDistanceController.text),
          maxDistanceKm: double.parse(_maxDistanceController.text),
          minWeightKg: double.parse(_minWeightController.text),
          maxWeightKg: double.parse(_maxWeightController.text),
          baseCharge: double.parse(_baseChargeController.text),
          ratePerKm: double.parse(_ratePerKmController.text),
          ratePerKg: double.parse(_ratePerKgController.text),
          minimumCharge: double.parse(_minimumChargeController.text),
          carrierPercentage: double.parse(_carrierPercentageController.text),
          shopPercentage: double.parse(_shopPercentageController.text),
          adminPercentage: double.parse(_adminPercentageController.text),
          isActive: _isActive,
          priority: int.parse(_priorityController.text),
        );

        if (response['success'] == true) {
          _showSnackBar("Rate card created successfully!", isError: false);
          _resetForm();
        } else {
          _showSnackBar(
            response['error'] ?? "Failed to create rate card",
            isError: true,
          );
        }
      } catch (e) {
        logger.e("Error creating rate card: $e");
        _showSnackBar("Error: $e", isError: true);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _minDistanceController.clear();
    _maxDistanceController.clear();
    _minWeightController.clear();
    _maxWeightController.clear();
    _baseChargeController.clear();
    _ratePerKmController.clear();
    _ratePerKgController.clear();
    _minimumChargeController.clear();
    _carrierPercentageController.clear();
    _shopPercentageController.clear();
    _adminPercentageController.clear();
    _priorityController.clear();
    setState(() {
      _isActive = true;
      _isNameNull = false;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Rate Management",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Create Rate Card Form Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.add_card,
                                    color: Colors.red.shade700,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Create New Rate Card",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Name Field with null option
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            "Rate Card Name",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _nameController,
                                          enabled: !_isNameNull,
                                          decoration: InputDecoration(
                                            hintText: "e.g., Standard Delivery",
                                            prefixIcon: Icon(
                                              Icons.label,
                                              color: Colors.red.shade700,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                            suffixIcon:
                                                !_isNameNull &&
                                                    _nameController
                                                        .text
                                                        .isNotEmpty
                                                ? IconButton(
                                                    icon: Icon(
                                                      Icons.clear,
                                                      size: 18,
                                                    ),
                                                    onPressed: () =>
                                                        _nameController.clear(),
                                                  )
                                                : null,
                                          ),
                                          validator: (value) {
                                            if (!_isNameNull &&
                                                (value == null ||
                                                    value.isEmpty)) {
                                              return "Please enter a name or check Null option";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Distance Range
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Min Distance (km)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller:
                                                  _minDistanceController,

                                              icon: Icons.straighten,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Min distance",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Max Distance (km)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller:
                                                  _maxDistanceController,

                                              icon: Icons.straighten,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Max distance",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Weight Range
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Min Weight (kg)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller: _minWeightController,

                                              icon: Icons.fitness_center,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Min weight",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Max Weight (kg)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller: _maxWeightController,

                                              icon: Icons.fitness_center,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Max weight",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Charges Row
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Base Charge (₹)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller: _baseChargeController,

                                              icon: Icons.currency_rupee,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Base charge",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Rate per km (₹)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller: _ratePerKmController,

                                              icon: Icons.speed,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Rate per km",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Rate per kg and Minimum charge
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Rate per kg (₹)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller: _ratePerKgController,

                                              icon: Icons.fitness_center,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Rate per kg",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Minimum Charge (₹)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller:
                                                  _minimumChargeController,

                                              icon: Icons.currency_rupee,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Minimum charge",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Percentages Row
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Carrier Percentage (%)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller:
                                                  _carrierPercentageController,

                                              icon: Icons.person,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Carrier percentage",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Shop Percentage (%)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller:
                                                  _shopPercentageController,

                                              icon: Icons.store,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Shop percentage",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Admin percentage and Priority
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Admin Percentage (%)",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller:
                                                  _adminPercentageController,

                                              icon: Icons.admin_panel_settings,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Admin percentage",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Priority",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _buildInputField(
                                              controller: _priorityController,

                                              icon: Icons.priority_high,
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (value) =>
                                                  _validateRequired(
                                                    value,
                                                    "Priority",
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Active Status Switch
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _isActive
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isActive
                                            ? Colors.green.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                _isActive
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: _isActive
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  "Active Status",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: _isActive
                                                        ? Colors.green.shade700
                                                        : Colors.grey.shade700,
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: _isActive,
                                          onChanged: (value) {
                                            setState(() {
                                              _isActive = value;
                                            });
                                          },
                                          activeColor: Colors.red.shade700,
                                          activeTrackColor: Colors.red.shade100,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _createRateCard, // This now works correctly
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.save),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    "Create Rate Card",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,

    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.red.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return "$fieldName is required";
    }
    if (double.tryParse(value) == null) {
      return "Please enter a valid number";
    }
    return null;
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
