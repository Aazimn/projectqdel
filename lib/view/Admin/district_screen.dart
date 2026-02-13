import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';

class DistrictScreen extends StatefulWidget {
  const DistrictScreen({super.key});

  @override
  State<DistrictScreen> createState() => _DistrictScreenState();
}

class _DistrictScreenState extends State<DistrictScreen> {
  TextEditingController districtctl = TextEditingController();
  TextEditingController statectl = TextEditingController();
  ApiService apiService = ApiService();
  late Future<List<dynamic>> statefuture;
  late Future<List<dynamic>> districtfuture;

  int? selectedCountryId;
  int? selectedStateId;

  List countries = [];
  List states = [];
  bool loadingStates = false;
  late Future<void> initialLoad;

  @override
  void initState() {
    super.initState();
    initialLoad = loadInitialData();
    districtfuture = apiService.districtList();
  }

  Future<void> loadInitialData() async {
    final countryData = await apiService.countriesList();
    final stateData = await apiService.statesList();

    setState(() {
      countries = countryData;
      states = stateData;
    });
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
            "District",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),
      body: FutureBuilder(
        future: initialLoad,
        builder: (context, initSnap) {
          if (initSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<List<dynamic>>(
            future: districtfuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Center(child: Text("No Districts found"));
              }
              final districtdata = snapshot.data!;
              return ListView.builder(
                itemCount: districtdata.length,
                itemBuilder: (context, index) {
                  final district = districtdata[index];
                  final state = states.firstWhere(
                    (s) => s['id'] == district['state'],
                    orElse: () => {},
                  );
                  final country = countries.firstWhere(
                    (c) => c['id'] == state['country'],
                    orElse: () => {},
                  );
                  return ListTile(
                    title: Text(
                      district['name'],
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "State : ${state['name'] ?? "Unknown"}\n"
                      "Country : ${state['country'] ?? "Unknown"}",
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
                            await apiService.deleteDistrict(
                              districtId: district["id"],
                            );
                            setState(() {
                              districtfuture = apiService.districtList();
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void showUpdateDialog(Map district) async {
    if (countries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Countries not loaded yet")));
      return;
    }
    districtctl.text = district['name'];

    selectedStateId = district['state'];
    Map? stateData = states.firstWhere(
      (s) => s['id'] == district['state'],
      orElse: () => {},
    );

    selectedCountryId = stateData != null ? stateData['country'] : null;
    if (selectedCountryId != null) {
      states = await apiService.getStates(countryId: selectedCountryId!);
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: ColorConstants.textfieldgrey,
            title: const Text("Update District"),
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
                  onChanged: (value) async {
                    setDialogState(() {
                      selectedCountryId = value;
                      loadingStates = true;
                      states.clear();
                      selectedStateId = null;
                    });

                    final data = await apiService.getStates(countryId: value!);

                    setDialogState(() {
                      states = data;
                      loadingStates = false;
                    });
                  },
                ),

                const SizedBox(height: 10),

                loadingStates
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<int>(
                        value: selectedStateId,
                        hint: const Text("Select State"),
                        isExpanded: true,
                        items: states.map<DropdownMenuItem<int>>((s) {
                          return DropdownMenuItem<int>(
                            value: s['id'],
                            child: Text(s['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedStateId = value;
                          });
                        },
                      ),

                const SizedBox(height: 10),
                TextField(
                  controller: districtctl,
                  decoration: const InputDecoration(labelText: "District Name"),
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
                  if (districtctl.text.isEmpty || selectedStateId == null)
                    return;

                  await apiService.updateDistrict(
                    districtId: district['id'],
                    name: districtctl.text.trim(),
                    stateId: selectedStateId!,
                  );
                  Navigator.pop(context);
                  setState(() {
                    districtfuture = apiService.districtList();
                  });

                  districtctl.clear();
                  selectedStateId = null;
                  selectedCountryId = null;
                },
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ColorConstants.textfieldgrey,
              title: const Text("Add District"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    hint: const Text("Select Country"),
                    value: selectedCountryId,
                    isExpanded: true,
                    items: countries.map<DropdownMenuItem<int>>((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'],
                        child: Text(c['name']),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setDialogState(() {
                        selectedCountryId = value;
                        loadingStates = true;
                        states.clear();
                        selectedStateId = null;
                      });

                      final data = await apiService.getStates(
                        countryId: value!,
                      );

                      setDialogState(() {
                        states = data;
                        loadingStates = false;
                      });
                    },
                  ),

                  const SizedBox(height: 10),
                  loadingStates
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int>(
                          hint: const Text("Select State"),
                          value: selectedStateId,
                          isExpanded: true,
                          items: states.map<DropdownMenuItem<int>>((s) {
                            return DropdownMenuItem<int>(
                              value: s['id'],
                              child: Text(s['name']),
                            );
                          }).toList(),
                          onChanged: states.isEmpty
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedStateId = value;
                                  });
                                },
                        ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: statectl,
                    decoration: const InputDecoration(
                      labelText: "District Name",
                    ),
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
                    if (statectl.text.isEmpty || selectedStateId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select state and enter district",
                          ),
                        ),
                      );
                      return;
                    }

                    final success = await apiService.addDistrict(
                      name: statectl.text.trim(),
                      stateId: selectedStateId!,
                    );

                    if (success) {
                      Navigator.pop(context);
                      setState(() {
                        districtfuture = apiService.districtList();
                      });
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
