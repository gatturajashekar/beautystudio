import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'gallery_page.dart';
import 'serviceslist.dart';
import 'profile.dart';
import 'offerspage.dart';
import 'history.dart';

// ================= API ENDPOINTS =================

const String HOMEPAGE_IMAGES_API =
    "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/images/homepage";

const String REVIEWS_URL =
    "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/getReviews";

// ================= HOME PAGE =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final String salonLocationUrl =
      "https://maps.app.goo.gl/Ti366oNUxSdfLdLq8?g_st=ipc";

  // ---------------- Homepage Images ----------------
  List<String> _homepageImages = [];
  bool _loadingImages = true;

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  // ---------------- Reviews ----------------
  List<Map<String, dynamic>> reviews = [];
  bool loadingReviews = true;

  // ================= INIT / DISPOSE =================

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadHomepageImages();
    _loadReviews();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ================= AUTO SLIDE =================

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_homepageImages.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % _homepageImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // ================= LOAD HOMEPAGE IMAGES =================

  Future<void> _loadHomepageImages() async {
    try {
      final res = await http.get(Uri.parse(HOMEPAGE_IMAGES_API));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list = decoded["images"] ?? [];

        _homepageImages = list.map((e) => e.toString()).toList();
        _startAutoSlide();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingImages = false);
    }
  }

  // ================= LOAD REVIEWS =================

  Future<void> _loadReviews() async {
    try {
      final res = await http.get(Uri.parse(REVIEWS_URL));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final all = List<Map<String, dynamic>>.from(data["reviews"] ?? []);
        reviews = all.where((r) {
          final rating = int.tryParse(r["rating"].toString()) ?? 0;
          return rating >= 4;
        }).toList();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => loadingReviews = false);
    }
  }

  // ================= HELPERS =================

  void _openMap() async => await launchUrl(Uri.parse(salonLocationUrl));

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }

  // ================= IMAGE SLIDER =================

  Widget _imageSlider() {
    if (_loadingImages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_homepageImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _homepageImages.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              _homepageImages[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) =>
                  const Center(child: Icon(Icons.broken_image)),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          child: Row(
            children: List.generate(
              _homepageImages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 10 : 7,
                height: _currentPage == i ? 10 : 7,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= HOME UI =================

  Widget _homePageUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GestureDetector(
            onTap: _openMap,
            child: Row(
              children: const [
                Icon(Icons.location_on, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  "Puppalguda, Hyderabad",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            "MadhuBeautyStudio",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 12),

        _quickActions(44),

        const SizedBox(height: 12),

        Expanded(flex: 5, child: _imageSlider()),

        const SizedBox(height: 10),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            "Latest Reviews",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 6),

        // ================= UPDATED REVIEWS START =================
        Expanded(
          flex: 3,
          child: loadingReviews
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: reviews.length,
                  itemBuilder: (_, i) {
                    final r = reviews[i];
                    final rating =
                        int.tryParse(r["rating"].toString()) ?? 0;

                    final servicesList = <String>[];

                    if (r["services"] != null && r["services"] is List) {
                      for (var s in r["services"]) {
                        servicesList.add(s.toString());
                      }
                    } else if (r["serviceName"] != null) {
                      servicesList.add(r["serviceName"].toString());
                    }

                    return GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (_) {
                            return DraggableScrollableSheet(
                              expand: false,
                              maxChildSize: 0.95,
                              minChildSize: 0.35,
                              initialChildSize: 0.55,
                              builder: (context, controller) {
                                return Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: ListView(
                                    controller: controller,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Rating",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildStars(rating),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Comment",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        r["comment"] ?? "",
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Services",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      ...servicesList
                                          .map((s) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 2),
                                                child: Text(
                                                  "• $s",
                                                  style: const TextStyle(
                                                      fontSize: 15),
                                                ),
                                              ))
                                          .toList(),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 260,
                        margin: const EdgeInsets.only(left: 18),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStars(rating),
                            const SizedBox(height: 6),
                            Text(
                              r["comment"] ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Services",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            ...servicesList
                                .map(
                                  (s) => Text(
                                    "• $s",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // ================= UPDATED REVIEWS END =================
      ],
    );
  }

  // ================= QUICK ACTIONS =================

  Widget _quickActions(double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 1),
          child: Column(
            children: [
              Icon(Icons.bolt, color: Colors.green, size: iconSize),
              const SizedBox(height: 6),
              const Text("Quick Book"),
            ],
          ),
        ),
        _quickItem(Icons.manage_history, "My Bookings", Colors.purple,
            iconSize, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistoryPage()),
          );
        }),
        _quickItem(Icons.local_offer, "Offers", Colors.orange, iconSize, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OffersPage()),
          );
        }),
      ],
    );
  }

  Widget _quickItem(
      IconData icon, String label, Color color, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.content_cut), label: "Book"),
          BottomNavigationBarItem(
              icon: Icon(Icons.photo_library), label: "Gallery"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(child: _homePageUI()),
          const ServicesListPage(),
          const GalleryPage(),
          const ProfilePage(),
        ],
      ),
    );
  }
}
