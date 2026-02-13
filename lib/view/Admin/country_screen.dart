import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  TextEditingController countryctl = TextEditingController();
  ApiService apiService = ApiService();
  late Future<List<dynamic>> countryFuture;

  @override
  void initState() {
    super.initState();
    countryFuture = apiService.countriesList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorConstants.red,
        onPressed: () {
          showAddDialog();
        },
        child: Text(
          "Add",
          style: TextStyle(color: ColorConstants.white, fontSize: 20),
        ),
      ),
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Country",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: countryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No countries found"));
          }

          final countries = snapshot.data!;

          return ListView.builder(
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];

              return ListTile(
                title: Text(
                  country['name'],
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showUpdateDialog(
                          countryId: country['id'],
                          oldName: country['name'],
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await apiService.deleteCountry(
                          countryId: country["id"],
                        );
                        setState(() {
                          countryFuture = apiService.countriesList();
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showUpdateDialog({required int countryId, required String oldName}) {
    countryctl.text = oldName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorConstants.textfieldgrey,
          title: const Text("Update Country"),
          content: TextField(
            controller: countryctl,
            decoration: const InputDecoration(labelText: "Country Name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                countryctl.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = countryctl.text.trim();
                if (name.isEmpty) return;

                bool success = await apiService.updateCountry(
                  countryId: countryId,
                  name: name,
                );

                if (success) {
                  Navigator.pop(context);
                  countryctl.clear();
                  setState(() {
                    countryFuture = apiService.countriesList();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to update country")),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorConstants.textfieldgrey,
          title: const Text("Add Country"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countryctl,
                decoration: InputDecoration(labelText: "Country Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = countryctl.text.trim();
                if (name.isEmpty) return;
                bool success = await apiService.addCountry(name: name);
                if (success) {
                  Navigator.pop(context);
                  setState(() {
                    countryFuture = apiService.countriesList();
                  });
                  countryctl.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to add country")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
