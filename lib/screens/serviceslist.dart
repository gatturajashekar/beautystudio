import 'dart:async';
import 'package:flutter/material.dart';

import 'cart.dart';
import 'globalcart.dart';
import '../services_api.dart';

class ServicesListPage extends StatefulWidget {
  const ServicesListPage({super.key});

  // ⭐ HomeScreen search → Services search link
  static final searchStream = StreamController<String>.broadcast();

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage>
    with SingleTickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> categoryServices = {};
  List<Map<String, dynamic>> filteredServices = [];
  List<String> categories = [];

  String selectedGender = "All";
  String selectedCategory = "All";
  String searchText = "";

  bool isLoading = true;
  String? error;

  TabController? _tabController;

  // Theme Colors (unchanged)
  final Color crepeBG = const Color(0xFFF4E2D8);
  final Color goldAccent = const Color(0xFFE7B872);
  final Color deepBrown = const Color(0xFF4A3426);

  @override
  void initState() {
    super.initState();

    ServicesListPage.searchStream.stream.listen((query) {
      setState(() => searchText = query);
      applyFilters();
    });

    fetchCategories();
  }

  // ---------------------------------------------------------------------------
  // FETCH CATEGORIES (NO UI CHANGE)
  // ---------------------------------------------------------------------------
  Future<void> fetchCategories() async {
    setState(() => isLoading = true);

    try {
      final all = await ServicesApi.getServicesByCategory("All");

      categories =
          all.map((s) => s["category"].toString()).toSet().toList();
      categories.sort();
      categories.insert(0, "All");

      _tabController = TabController(length: categories.length, vsync: this);
      _tabController!.addListener(() {
        if (_tabController!.indexIsChanging) return;
        selectedCategory = categories[_tabController!.index];
        fetchServicesByCategory(selectedCategory);
      });

      selectedCategory = categories[0];
      await fetchServicesByCategory(selectedCategory);
    } catch (e) {
      error = "Error loading categories";
      isLoading = false;
    }
  }

  // ---------------------------------------------------------------------------
  // FETCH SERVICES FOR CATEGORY (LOGIC ONLY CHANGED)
  // ---------------------------------------------------------------------------
  Future<void> fetchServicesByCategory(String category) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    if (categoryServices.containsKey(category)) {
      applyFilters();
      setState(() => isLoading = false);
      return;
    }

    try {
      final services =
          await ServicesApi.getServicesByCategory(category);

      categoryServices[category] = services;
      applyFilters();
    } catch (_) {
      error = "Error loading services";
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // FILTER LOGIC (UNCHANGED)
  // ---------------------------------------------------------------------------
  void applyFilters() {
    final services = categoryServices[selectedCategory] ?? [];

    filteredServices = services.where((service) {
      final matchGender =
          selectedGender == "All" || service["gender"] == selectedGender;

      final matchSearch =
          searchText.isEmpty ||
              service["serviceName"]
                  .toLowerCase()
                  .contains(searchText.toLowerCase());

      return matchGender && matchSearch;
    }).toList();

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // UI (100% UNCHANGED)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        backgroundColor: goldAccent,
        elevation: 0,
        title: Text(
          "Salon Services",
          style: TextStyle(
            color: deepBrown,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: _tabController == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: deepBrown,
                    unselectedLabelColor: Colors.grey[700],
                    indicatorColor: goldAccent,
                    indicatorWeight: 4,
                    tabs: categories.map((c) => Tab(text: c)).toList(),
                  ),
                ),
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      child: TextField(
                        onChanged: (value) {
                          searchText = value;
                          applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: "Search services...",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              Icon(Icons.search, color: deepBrown, size: 22),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        genderChip("All"),
                        const SizedBox(width: 8),
                        genderChip("Male"),
                        const SizedBox(width: 8),
                        genderChip("Female"),
                      ],
                    ),
                    Expanded(
                      child: filteredServices.isEmpty
                          ? const Center(
                              child: Text("No services available"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filteredServices.length,
                              itemBuilder: (context, index) {
                                final service =
                                    filteredServices[index];

                                return Card(
                                  color: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(15),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service["serviceName"],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: deepBrown,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Gender: ${service["gender"]}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: deepBrown,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          service["description"] ?? "",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Text(
                                              "₹${service["cost"]}",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color:
                                                    Colors.green[700],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  globalCart
                                                      .add(service);
                                                });
                                              },
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(
                                                        0xFFF5DEB3),
                                                foregroundColor:
                                                    deepBrown,
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 18,
                                                        vertical: 8),
                                              ),
                                              child: const Text("Add"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: globalCart.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: goldAccent,
              foregroundColor: deepBrown,
              icon: const Icon(Icons.shopping_cart),
              label: Text("Cart (${globalCart.length})"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CartPage(
                      cart: globalCart,
                      onRemove: (item) {
                        setState(() => globalCart.remove(item));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget genderChip(String gender) {
    bool selected = selectedGender == gender;

    return ChoiceChip(
      label: Text(
        gender,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : deepBrown,
        ),
      ),
      selected: selected,
      selectedColor: goldAccent,
      backgroundColor: Colors.white,
      onSelected: (_) {
        selectedGender = gender;
        applyFilters();
      },
    );
  }
}
