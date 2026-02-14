import 'package:flutter/material.dart';
import 'package:projectqdel/core/constants/color_constants.dart';
import 'package:projectqdel/services/api_service.dart';
import 'package:projectqdel/view/Admin/add_country.dart';
import 'package:projectqdel/view/Admin/state_screen.dart';
import 'package:projectqdel/view/Admin/update_country.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  TextEditingController countryctl = TextEditingController();
  TextEditingController searchCtl = TextEditingController();
  TextEditingController countryCodeCtl = TextEditingController();
  ApiService apiService = ApiService();
  List<dynamic> _allCountries = [];
  List<dynamic> _filteredCountries = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
    fetchCountries();
  }

  Future<void> loadData() async {
    await ApiService.loadSession();
    await fetchCountries();
  }

  Future<void> fetchCountries() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await apiService.countriesList();
      setState(() {
        _allCountries = data;
        _filteredCountries = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading countries: $e")));
    }
  }

  void _searchCountry(String query) {
    final results = _allCountries.where((country) {
      final name = country['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() {
      _filteredCountries = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.bgred,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: ColorConstants.red,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.red.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCountryScreen()),
              );
              if (result == true) fetchCountries();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Add New Country",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: ColorConstants.red,
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Manage Countries",
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchCtl,
              onChanged: _searchCountry,
              decoration: InputDecoration(
                hintText: "Search country...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: ColorConstants.textfieldgrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCountries.isEmpty
                ? const Center(child: Text("No countries found"))
                : ListView.builder(
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StateScreen(
                                  countryId: country['id'],
                                  countryName: country['name'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 38,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "🌍",
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: ColorConstants.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Code: +${country['code'] ?? ''}",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: ColorConstants.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, size: 15),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UpdateCountryScreen(
                                            countryId: country['id'],
                                            name: country['name'],
                                            code: country['code'],
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        fetchCountries();
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(width: 8),
                                Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 15,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      await apiService.deleteCountry(
                                        countryId: country['id'],
                                      );
                                      fetchCountries();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
