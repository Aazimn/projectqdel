import 'package:flutter/material.dart';
import 'package:projectqdel/model/delivery_model.dart';
import 'package:projectqdel/services/api_service.dart';

class DeliveryModesAdmin extends StatefulWidget {
  const DeliveryModesAdmin({super.key});

  @override
  State<DeliveryModesAdmin> createState() => _DeliveryModesAdminState();
}

class _DeliveryModesAdminState extends State<DeliveryModesAdmin> {
  final ApiService apiService = ApiService();
  List<DeliveryMode> deliveryModes = [];
  bool isLoading = true;
  bool isProcessing = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController discriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDeliveryModes();
  }

  @override
  void dispose() {
    nameController.dispose();
    discriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchDeliveryModes() async {
    setState(() => isLoading = true);
    try {
      final modes = await apiService.getDeliveryModes();
      setState(() {
        deliveryModes = modes;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error fetching delivery modes: $e', isError: true);
    }
  }

  Future<void> addDeliveryMode() async {
    if (nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a delivery mode name', isError: true);
      return;
    }
    if (discriptionController.text.trim().isEmpty) {
      _showSnackBar('Please enter a delivery mode Discription', isError: true);
      return;
    }

    setState(() => isProcessing = true);
    try {
      final success = await apiService.createDeliveryMode(
        nameController.text.trim(),
        discriptionController.text.trim(),
      );

      if (success) {
        _showSnackBar('Delivery mode added successfully ✅', isError: false);
        nameController.clear();
        discriptionController.clear();
        await fetchDeliveryModes();
        Navigator.pop(context);
      } else {
        _showSnackBar('Failed to add delivery mode ❌', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> updateDeliveryMode(DeliveryMode mode) async {
    nameController.text = mode.name;
    discriptionController.text = mode.discription;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Edit Delivery Mode',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Mode Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              autofocus: true,
            ),
            SizedBox(height: 15),
            TextField(
              controller: discriptionController,
              decoration: const InputDecoration(
                labelText: 'Mode Discription',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.details),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true &&
        nameController.text.trim().isNotEmpty &&
        discriptionController.text.trim().isNotEmpty) {
      setState(() => isProcessing = true);
      try {
        final success = await apiService.updateDeliveryMode(
          mode.id!,
          nameController.text.trim(),
          discriptionController.text.trim(),
        );

        if (success) {
          _showSnackBar('Delivery mode updated successfully ✅', isError: false);
          await fetchDeliveryModes();
        } else {
          _showSnackBar('Failed to update delivery mode ❌', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      } finally {
        setState(() => isProcessing = false);
        nameController.clear();
        discriptionController.clear();
      }
    }
  }

  Future<void> deleteDeliveryMode(DeliveryMode mode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Delivery Mode',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Are you sure you want to delete "${mode.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isProcessing = true);
      try {
        final success = await apiService.deleteDeliveryMode(mode.id!);

        if (success) {
          _showSnackBar('Delivery mode deleted successfully ✅', isError: false);
          await fetchDeliveryModes();
        } else {
          _showSnackBar('Failed to delete delivery mode ❌', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      } finally {
        setState(() => isProcessing = false);
      }
    }
  }

  void showAddDialog() {
    nameController.clear();
    discriptionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Delivery Mode',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Mode Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
              autofocus: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: discriptionController,
              decoration: const InputDecoration(
                labelText: 'Mode Discription',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.details_outlined),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.clear();
              discriptionController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: addDeliveryMode,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text(
          'Delivery Modes Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchDeliveryModes,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            )
          : deliveryModes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No delivery modes added',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: showAddDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add First Mode',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchDeliveryModes,
              color: Colors.red,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: deliveryModes.length,
                itemBuilder: (context, index) {
                  final mode = deliveryModes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            mode.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            mode.discription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => updateDeliveryMode(mode),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => deleteDeliveryMode(mode),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
