// profile.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'history.dart';
import 'profilefeature.dart';
import 'reviewcenter.dart';
import 'offerspage.dart';
import 'authentication.dart';

const String apiBase =
    "https://szbj7qys97.execute-api.us-east-1.amazonaws.com/prod";

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;

  final Color crepe = const Color(0xFFF5DEB3);
  final Color textDark = Colors.brown;
  final Color gold = const Color(0xFFD6A86A);

  String? userId;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // ==========================
  // LOAD USER (FIREBASE SOURCE)
  // ==========================
  Future<void> loadUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
        return;
      }

      userId = firebaseUser.uid;

      final res = await http.get(
        Uri.parse("$apiBase/user?userId=$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode != 200 || res.body.isEmpty) {
        throw Exception("Failed to load user");
      }

      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception("Invalid user data");
      }

      if (!mounted) return;
      setState(() {
        user = decoded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> refreshAfter(dynamic result, String msg) async {
    if (result == true) {
      await loadUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  // ==========================
  // LOGOUT (PROPER)
  // ==========================
  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("isAdmin");
    await prefs.remove("adminToken");
    await prefs.remove("profileCompleted");

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: crepe,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : user == null
                ? const Center(child: Text("Failed to load profile"))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 22),
                    child: Column(
                      children: [
                        _headerCard(),
                        const SizedBox(height: 28),
                        _quickActions(),
                        const SizedBox(height: 35),
                        _benefitsSection(),
                        const SizedBox(height: 35),
                        _settingsSection(),
                        const SizedBox(height: 35),
                        _logoutButton(),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ==========================
  // UI — UNCHANGED
  // ==========================
  Widget _headerCard() {
    return Card(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFF5DEB3),
              child: Icon(Icons.person, size: 28, color: textDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                (user?["name"]?.toString().isNotEmpty ?? false)
                    ? user!["name"]
                    : "User",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  height: 1.1,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      initialUser: user,
                      isNewUser: false,
                    ),
                  ),
                );
                await refreshAfter(result, "Profile updated");
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Edit",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(
          icon: Icons.history,
          title: "Bookings",
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HistoryPage())),
        ),
        _quickAction(
          icon: Icons.call,
          title: "Call",
          onTap: () => launchUrl(Uri(scheme: 'tel', path: '+919701523552')),
        ),
        _quickAction(
          icon: Icons.chat,
          title: "Chat",
          onTap: () => launchUrl(
            Uri.parse("https://wa.me/919701523552"),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Icon(icon, size: 28, color: textDark),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Exclusive Benefits",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark)),
        const SizedBox(height: 10),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.group_add,
                title: "Refer a Friend",
                onTap: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ReferFriendPage()));
                  await refreshAfter(result, "Referral applied");
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.star_rate,
                title: "My Reviews",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReviewCenterPage())),
              ),
              _divider(),
              _settingsTile(
                icon: Icons.monetization_on,
                title: "Beauty Coins",
                onTap: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BeautyCoinsPage()));
                  await refreshAfter(result, "Coins Updated");
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.local_offer,
                title: "Offers",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OffersPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Settings",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textDark)),
        const SizedBox(height: 10),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _settingsTile(
                icon: Icons.article,
                title: "Terms & Conditions",
                onTap: () => launchUrl(
                  Uri.parse("https://madhusbeautystudio.com/"),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _divider(),
              _settingsTile(
                icon: Icons.privacy_tip,
                title: "Privacy Policy",
                onTap: () => launchUrl(
                  Uri.parse("https://madhusbeautystudio.com/"),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _divider(),
              _settingsTile(
                icon: Icons.info,
                title: "About Us",
                onTap: () => _showAbout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textDark),
      title: Text(title, style: TextStyle(color: textDark, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade300);

  void _showAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutPage()),
    );
  }

  Widget _logoutButton() {
    return ElevatedButton.icon(
      onPressed: logout,
      icon: const Icon(Icons.logout),
      label: const Text("Logout"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}