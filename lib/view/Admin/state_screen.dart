import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class StateScreen extends StatefulWidget {
  const StateScreen({super.key});

  @override
  State<StateScreen> createState() => _StateScreenState();
}

class _StateScreenState extends State<StateScreen> {
  TextEditingController contryctl = TextEditingController();
  TextEditingController statectl = TextEditingController();
  ApiService apiService = ApiService();
  late Future<List<dynamic>> statefuture;
  late Future<List<dynamic>> countryfuture;

  int? selectedCountryId;
  List countries = [];

  @override
  void initState() {
    super.initState();
    loadCountries();
    statefuture = apiService.statesList();
  }

  Future<void> loadCountries() async {
    try {
      final data = await apiService.countriesList();
      setState(() {
        countries = data;
      });
    } catch (e) {
      print("Error loading countries: $e");
    }
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
            "state",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: statefuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No States found"));
          }

          final statesdata = snapshot.data!;

          return ListView.builder(
            itemCount: statesdata.length,
            itemBuilder: (context, index) {
              final state = statesdata[index];

              return ListTile(
                title: Text(
                  state['name'],
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "Country ID : ${state['country']}",
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showUpdateDialog(state);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await apiService.deleteState(stateId: state["id"]);
                        setState(() {
                          statefuture = apiService.statesList();
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

  void showUpdateDialog(Map state) {
    if (countries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Countries not loaded yet")));
      return;
    }

    statectl.text = state['name'];

    // ✅ ensure value exists in dropdown
    final countryExists = countries.any((c) => c['id'] == state['country']);

    selectedCountryId = countryExists ? state['country'] : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ColorConstants.textfieldgrey,
        title: const Text("Update State"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedCountryId,
              hint: const Text("Select Country"),
              isExpanded: true,
              items: countries.map<DropdownMenuItem<int>>((c) {
                return DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCountryId = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: statectl,
              decoration: const InputDecoration(labelText: "State Name"),
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
              if (statectl.text.isEmpty || selectedCountryId == null) return;

              await apiService.updateState(
                stateId: state['id'],
                name: statectl.text.trim(),
                countryId: selectedCountryId!,
              );

              Navigator.pop(context);
              setState(() {
                statefuture = apiService.statesList();
              });

              statectl.clear();
              selectedCountryId = null;
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // void showUpdateDialog(Map state) {
  //   statectl.text = state['name'];
  //   selectedCountryId = state['country'];

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         backgroundColor: ColorConstants.textfieldgrey,
  //         title: const Text("Update State"),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             DropdownButtonFormField<int>(
  //               value: selectedCountryId,
  //               isExpanded: true,
  //               hint: const Text("Select Country"),
  //               items: countries.map<DropdownMenuItem<int>>((c) {
  //                 return DropdownMenuItem<int>(
  //                   value: c['id'],
  //                   child: Text(c['name']),
  //                 );
  //               }).toList(),
  //               onChanged: (value) {
  //                 setState(() {
  //                   selectedCountryId = value;
  //                 });
  //               },
  //             ),
  //             const SizedBox(height: 10),
  //             TextField(
  //               controller: statectl,
  //               decoration: const InputDecoration(labelText: "State Name"),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               statectl.clear();
  //               Navigator.pop(context);
  //             },
  //             child: const Text("Cancel"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               String name = statectl.text.trim();

  //               if (name.isEmpty || selectedCountryId == null) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(
  //                     content: Text("Please enter state and select country"),
  //                   ),
  //                 );
  //                 return;
  //               }

  //               bool success = await apiService.updateState(
  //                 stateId: state['id'],
  //                 name: name,
  //                 countryId: selectedCountryId!,
  //               );

  //               if (success) {
  //                 Navigator.pop(context);
  //                 setState(() {
  //                   statefuture = apiService.statesList();
  //                 });

  //                 statectl.clear();
  //                 selectedCountryId = null;
  //               } else {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(content: Text("Failed to update State")),
  //                 );
  //               }
  //             },
  //             child: const Text("Update"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ColorConstants.textfieldgrey,
          title: const Text("Add State"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCountryId,
                hint: const Text("Select Country"),
                isExpanded: true,
                items: countries.map<DropdownMenuItem<int>>((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text(c['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCountryId = value;
                  });
                },
              ),

              const SizedBox(height: 10),

              TextField(
                controller: statectl,
                decoration: const InputDecoration(labelText: "State Name"),
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
                String name = statectl.text.trim();

                if (name.isEmpty || selectedCountryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter state and select country"),
                    ),
                  );
                  return;
                }

                bool success = await apiService.addstates(
                  name: name,
                  country: selectedCountryId!,
                );

                if (success) {
                  Navigator.pop(context);

                  setState(() {
                    statefuture = apiService.statesList();
                  });

                  statectl.clear();
                  selectedCountryId = null;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to add State")),
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
