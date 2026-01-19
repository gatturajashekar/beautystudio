import 'package:flutter/material.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'addpictures.dart';
import 'adminhome.dart'; 
import 'manageusers.dart'; // <- You will create this screen for listing users 
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:madhubeautystudio/screens/authentication.dart';


class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  int _selectedIndex = 1; // Settings tab

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHome()),
      );
    }
  }

Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Confirm Logout'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 CLEAR ALL AUTH DATA (THIS IS THE FIX)
    await prefs.remove("authToken");
    await prefs.remove("userId");
    await prefs.remove("adminToken");
    await prefs.remove("adminEmail");
    await prefs.remove("isAdmin");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final topColor = Colors.orange.shade300;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1E0),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: topColor,
        centerTitle: true,
      ),

      // --------------------------
      // BODY
      // --------------------------
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingTile(
            title: 'Pictures',
            subtitle: 'User home page photos',
            icon: Icons.image,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUploadBanners()),
            ),
          ),
          _buildSettingTile(
            title: 'Users',
            subtitle: 'View app users',
            icon: Icons.people,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageUsersPage()),
            ),
          ),
          _buildSettingTile(
            title: 'Reviews',
            subtitle: 'Check customer reviews',
            icon: Icons.reviews,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewsPage()),
            ),
          ),
          _buildSettingTile(
            title: 'Offers',
            subtitle: 'Add or edit offers',
            icon: Icons.local_offer,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminOffersPage()),
            ),
          ),
          _buildSettingTile(
            title: 'Logout',
            subtitle: 'Sign out from admin account',
            icon: Icons.logout,
            onTap: _logout,
          ),
        ],
      ),

      // --------------------------
      // BOTTOM NAV
      // --------------------------
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
      ),
    );
  }

  // --------------------------
  // TILE BUILDER
  // --------------------------
  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }
}



class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  // ------------------------------
  // FORMAT DATE → 12 HOUR FORMAT
  // ------------------------------
  String formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final formatter = DateFormat("MMM d, yyyy • hh:mm a");
      return formatter.format(dt);
    } catch (e) {
      return isoString;
    }
  }

  // ------------------------------
  // FETCH REVIEWS
  // ------------------------------
  Future<List<Map<String, dynamic>>> fetchReviews() async {
    const url =
        "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/getReviews";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception("Failed: ${response.body}");
    }

    final jsonData = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(jsonData["reviews"] ?? []);
  }

  // ------------------------------
  // LOAD REVIEWS
  // ------------------------------
  void loadReviews() async {
    try {
      final list = await fetchReviews();
      setState(() {
        reviews = list;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        loading = false;
      });
    }
  }

  // ------------------------------
  // UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reviews")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text("Error: $errorMsg"))
              : ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final r = reviews[index];

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r["serviceName"] ?? "Unknown Service",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Rating: ${r["rating"]} ⭐",
                              style: const TextStyle(fontSize: 16),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Comment: ${r["comment"]?.isEmpty == true ? "No comment" : r["comment"]}",
                            ),

                            const SizedBox(height: 6),

                            Text("User: ${r["userId"]}"),
                            Text("Date: ${formatDate(r["createdAt"])}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
// admin_offers_page.dart
// Premium read-only Admin Offers page (Card Grid View - Option B)

// ---------------------- MODEL ----------------------
class Offer {
  final String offerId;
  final String title;
  final String description;
  final String type;
  final int value;
  final int minAmount;
  final String expiry;
  final bool isActive;
  final int usageLimit;
  final String imageUrl;

  Offer({
    required this.offerId,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.minAmount,
    required this.expiry,
    required this.isActive,
    required this.usageLimit,
    required this.imageUrl,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      offerId: json["offerId"] ?? "",
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      type: json["type"] ?? "flat",
      value: json["value"] ?? 0,
      minAmount: json["minAmount"] ?? 0,
      expiry: json["expiry"] ?? "",
      isActive: json["isActive"] ?? false,
      usageLimit: json["usageLimit"] ?? 1,
      imageUrl: json["imageUrl"] ?? "",
    );
  }

  String readableExpiry() {
    try {
      final d = DateTime.parse(expiry);
      const months = [
        "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${d.day} ${months[d.month]} ${d.year}";
    } catch (_) {
      return expiry;
    }
  }
}

// ---------------------- FETCH OFFERS ----------------------
Future<List<Offer>> fetchAdminOffers() async {
  final res = await http.get(
    Uri.parse("https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/offers"),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    final list = data["offers"] as List? ?? [];
    return list.map((e) => Offer.fromJson(e)).toList();
  }
  return [];
}

// ---------------------- PAGE ----------------------
class AdminOffersPage extends StatefulWidget {
  const AdminOffersPage({super.key});

  @override
  State<AdminOffersPage> createState() => _AdminOffersPageState();
}

class _AdminOffersPageState extends State<AdminOffersPage> {
  late Future<List<Offer>> _futureOffers;

  @override
  void initState() {
    super.initState();
    _futureOffers = fetchAdminOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offers (Admin View)"),
        backgroundColor: Colors.brown.shade300,
      ),
      body: FutureBuilder<List<Offer>>(
        future: _futureOffers,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final offers = snapshot.data!;
          if (offers.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _offerCard(offers[index]);
            },
          );
        },
      ),
    );
  }

  // ---------------------- OFFER CARD ----------------------
  Widget _offerCard(Offer offer) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            offer.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            offer.description,
            style: const TextStyle(color: Colors.black87),
          ),

          const SizedBox(height: 10),

          // Simple rows instead of chips
          _infoRow("Type", offer.type.toUpperCase()),
          _infoRow("Value", offer.type == "flat" ? "₹${offer.value}" : "${offer.value}%"),
          _infoRow("Minimum Amount", "₹${offer.minAmount}"),
          _infoRow("Expires", offer.readableExpiry()),
          _infoRow("Usage Limit", offer.usageLimit.toString()),

          const SizedBox(height: 10),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: offer.isActive ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              offer.isActive ? "ACTIVE" : "INACTIVE",
              style: TextStyle(
                color: offer.isActive ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  // Reusable info row
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
