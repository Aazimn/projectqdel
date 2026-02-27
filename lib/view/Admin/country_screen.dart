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

  Widget _header(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 130,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffF0625F)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),

        Positioned(
          top: 45,
          left: 16,
          child: _circleButton(
            Icons.arrow_back_ios_new,
            () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 45,
          right: 16,
          child: _circleButton(Icons.more_horiz, () {}),
        ),
        const Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              "Manage Countries",
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.red, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorConstants.red,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCountryScreen()),
          );

          if (result == true) {
            fetchCountries();
          }
        },
        child: const Text("Add"),
      ),
      body: Column(
        children: [
          _header(context),
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
                ? const Center(
                    child: Text(
                      "No countries found",
                      style: TextStyle(color: ColorConstants.black),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: countryCard(country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget countryCard(Map country) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ColorConstants.bgred),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorConstants.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.public, color: Colors.red, size: 22),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country['name'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.bgred,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "+${country['code'] ?? ''}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Divider(color: Colors.grey.shade200),

            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Update"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.green,
                      side: BorderSide(color: ColorConstants.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await apiService.deleteCountry(countryId: country['id']);
                      fetchCountries();
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("Delete"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
