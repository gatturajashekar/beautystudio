import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';            // ✅ ADDED
import 'package:share_plus/share_plus.dart';       // ✅ ADDED
import '../services_api.dart';
import 'homescreen.dart';
import 'globalcart.dart';
import 'cart.dart';
// =====================================================
// API CONFIG
// =====================================================

const String apiBase =
    "https://szbj7qys97.execute-api.us-east-1.amazonaws.com/prod";
const Duration apiTimeout = Duration(seconds: 15);

// =====================================================
// SINGLE SOURCE OF TRUTH — FIREBASE AUTH
// =====================================================

FirebaseUserData getFirebaseUser() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.phoneNumber == null) {
    throw Exception("Firebase user or phone number missing");
  }
  return FirebaseUserData(
    uid: user.uid,
    phone: user.phoneNumber!,
  );
}

class FirebaseUserData {
  final String uid;
  final String phone;
  FirebaseUserData({required this.uid, required this.phone});
}

Future<Map<String, dynamic>> postAction(Map<String, dynamic> body) async {
  final res = await http
      .post(
        Uri.parse("$apiBase/user"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      )
      .timeout(apiTimeout);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception("HTTP ${res.statusCode}: ${res.body}");
  }

  final data = jsonDecode(res.body);
  if (data is Map && data["success"] == false) {
    throw Exception(data["message"] ?? "Action failed");
  }

  return data is Map<String, dynamic> ? data : {};
}

// =====================================================
// EDIT / CREATE PROFILE
// =====================================================

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initialUser;
  final bool isNewUser;

  const EditProfilePage({
    super.key,
    required this.initialUser,
    required this.isNewUser,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameC;
  late final TextEditingController ageC;
  late final TextEditingController addressC;

  String gender = "Other";
  bool saving = false;

  final Color gold = const Color(0xFFD6A86A);
  final Color textDark = Colors.brown;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser ?? {};
    nameC = TextEditingController(text: u["name"] ?? "");
    ageC = TextEditingController(text: (u["age"] ?? "").toString());
    addressC = TextEditingController(text: u["address"] ?? "");
  }

  @override
  void dispose() {
    nameC.dispose();
    ageC.dispose();
    addressC.dispose();
    super.dispose();
  }

  // =====================================================
  // SAVE PROFILE — FIXED (phone INCLUDED)
  // =====================================================

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final fb = getFirebaseUser();

      final action =
          widget.isNewUser ? "createUser" : "updateProfile";

      await postAction({
        "action": action,
        "userId": fb.uid,
        "phone": fb.phone,
        "name": nameC.text.trim(),
        "age": int.parse(ageC.text.trim()),
        "gender": gender,
        "address": addressC.text.trim(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("profileCompleted", true);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5DEB3),
        elevation: 0,
        title: Text(
          widget.isNewUser ? "Create Profile" : "Edit Profile",
          style: const TextStyle(
              color: Colors.brown, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(
                controller: nameC,
                label: "Full Name",
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: ageC,
                label: "Age",
                icon: Icons.calendar_today,
                keyboard: TextInputType.number,
                validator: (v) {
                  final age = int.tryParse(v ?? "");
                  if (age == null || age < 1 || age > 120) {
                    return "Enter valid age";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: _input("Gender", Icons.person_outline),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => gender = v ?? "Other"),
              ),
              const SizedBox(height: 16),
              _field(
                controller: addressC,
                label: "Address",
                icon: Icons.home,
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: saving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.isNewUser ? "Create Profile" : "Save Changes",
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      maxLines: maxLines,
      decoration: _input(label, icon),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: textDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: textDark, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// =====================================================
// REFER FRIEND
// =====================================================

class ReferFriendPage extends StatefulWidget {
  const ReferFriendPage({super.key});

  @override
  State<ReferFriendPage> createState() => _ReferFriendPageState();
}

class _ReferFriendPageState extends State<ReferFriendPage> {
  final TextEditingController _controller = TextEditingController();
  bool submitting = false;

  final Color gold = const Color(0xFFD6A86A);
  final Color textDark = Colors.brown;

  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> applyReferral() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;

    if (code == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot refer yourself")),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      await postAction({
        "action": "applyReferral",
        "userId": userId,
        "referredBy": code,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Referral applied")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5DEB3),
        elevation: 0,
        title: const Text(
          "Refer a Friend",
          style: TextStyle(color: Colors.brown),
        ),
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Your Referral Code",
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userId,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: userId),
                          ),
                          icon: const Icon(Icons.copy),
                          label: const Text("Copy"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => Share.share(
                            "Use my referral code: $userId",
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Friend's Referral Code",
                prefixIcon:
                    Icon(Icons.person_add_alt_1, color: textDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitting ? null : applyReferral,
              style: ElevatedButton.styleFrom(backgroundColor: gold),
              child: submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Apply Referral",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// BEAUTY COINS (FIXED — FIREBASE UID)
// =====================================================

class BeautyCoinsPage extends StatefulWidget {
  const BeautyCoinsPage({super.key});

  @override
  State<BeautyCoinsPage> createState() => _BeautyCoinsPageState();
}

class _BeautyCoinsPageState extends State<BeautyCoinsPage> {
  int coins = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoins();
  }

  Future<void> _fetchCoins() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final c = await ServicesApi.getCoins(user.uid);

      if (!mounted) return;
      setState(() {
        coins = c;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _redeemNavigate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartPage(
          cart: globalCart,
          onRemove: (item) {},
          redeemMode: true,
          availableCoins: coins,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E2D8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4E2D8),
        elevation: 0,
        title: const Text(
          "Beauty Coins",
          style: TextStyle(
              fontSize: 22,
              color: Colors.brown,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.brown))
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    _coinsCard(),
                    const SizedBox(height: 50),
                    _redeemButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _coinsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD6A86A), Color(0xFFF4E2D8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 80, color: Color(0xFFD6A86A)),
          const SizedBox(height: 15),
          const Text(
            "Your Beauty Coins",
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF4A3426),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            coins.toString(),
            style: const TextStyle(
              fontSize: 68,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A3426),
            ),
          ),
        ],
      ),
    );
  }

  Widget _redeemButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _redeemNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD6A86A),
          foregroundColor: Colors.brown,
          padding: const EdgeInsets.symmetric(vertical: 20),
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: const Text(
          "Redeem Coins",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =====================================================
// ABOUT PAGE
// =====================================================

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5DEB3),
        elevation: 0,
        title: const Text(
          "About Us",
          style:
              TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: const SingleChildScrollView(
            child: Text(
              "For over 6+ years, Madhu’s Beauty Studio has been a trusted\n"
              "destination for premium beauty, styling, and self-care.\n\n"
              "We specialize in modern hair coloring, bridal styling,\n"
              "nail art & extensions, and professional beauty services —\n"
              "combining artistry with expert techniques to bring out\n"
              "your natural beauty.\n\n"
              "With a focus on hygiene, premium products, and personalized\n"
              "care, we ensure every client enjoys a comfortable and\n"
              "luxurious experience at an affordable price.\n\n"
              "Our mission is simple: deliver stylish, high-quality\n"
              "results that make you look and feel your absolute best.\n\n"
              "Thank you for choosing Madhu’s Beauty Studio —\n"
              "where beauty meets confidence.",
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.brown,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
