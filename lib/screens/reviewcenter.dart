// lib/screens/reviewcenter.dart
// PRODUCTION READY — REVIEW CENTER (Coins removed)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // ✅ REQUIRED

// API endpoints
const String GET_BOOKINGS_URL =
    "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/getBookings";
const String ADD_REVIEW_URL =
    "https://2vsy7j317d.execute-api.us-east-1.amazonaws.com/prod/reviews/add";

class ReviewCenterPage extends StatefulWidget {
  const ReviewCenterPage({super.key});

  @override
  State<ReviewCenterPage> createState() => _ReviewCenterPageState();
}

class _ReviewCenterPageState extends State<ReviewCenterPage> {
  bool loading = true;
  String? error;

  final Color crepeBG = const Color(0xFFF4E2D8);
  final Color goldAccent = const Color(0xFFD6A86A);
  final Color deepBrown = const Color(0xFF4A3426);

  List<Map<String, dynamic>> pendingBookings = [];
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};

  late String userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = "User not logged in";
          loading = false;
        });
        return;
      }

      userId = user.uid; // ✅ SINGLE SOURCE OF TRUTH
      await _fetchBookings();
    } catch (e) {
      setState(() {
        error = "Initialization failed: $e";
        loading = false;
      });
    }
  }

  Future<void> _fetchBookings() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse("$GET_BOOKINGS_URL?userId=$userId"));

      if (res.statusCode == 200) {
        final temp = await compute(_parseBookingsSync, res.body);

        for (var booking in temp) {
          final bookingId = booking["bookingId"].toString();
          _ratings[bookingId] = 0;
          _commentControllers[bookingId] = TextEditingController();
        }

        setState(() {
          pendingBookings = temp;
          error = null;
        });
      } else {
        throw Exception("Failed to fetch bookings: ${res.body}");
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  static List<Map<String, dynamic>> _parseBookingsSync(String body) {
    final data = jsonDecode(body);
    final completed = data["completed"] ?? [];
    final List<Map<String, dynamic>> temp = [];

    for (var item in completed) {
      if (item is! Map) continue;
      final status = (item["status"] ?? "").toString().trim().toLowerCase();
      final reviewed = item["reviewed"] == true ||
          item["reviewed"].toString() == "true";

      if (status != "completed" || reviewed) continue;
      temp.add(Map<String, dynamic>.from(item));
    }
    return temp;
  }

  bool _allRated(String bookingId) {
    final rating = _ratings[bookingId];
    return rating != null && rating > 0;
  }

  Future<void> _submitBookingReview(Map<String, dynamic> booking) async {
    final bookingId = booking["bookingId"].toString();
    final rating = _ratings[bookingId]!;
    final comment = _commentControllers[bookingId]!.text;

    if (rating <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a rating")),
      );
      return;
    }

    final body = {
      "userId": userId,
      "bookingId": bookingId,
      "rating": rating,
      "comment": comment.isEmpty ? null : comment,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await http.post(
        Uri.parse(ADD_REVIEW_URL),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      Navigator.pop(context);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _fetchBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${res.body}")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Network error: $e")));
    }
  }

  Widget _starRow(String bookingId) {
    final current = _ratings[bookingId] ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            star <= current ? Icons.star : Icons.star_border,
            color: star <= current ? Colors.amber : Colors.grey,
            size: 22,
          ),
          onPressed: () => setState(() => _ratings[bookingId] = star),
        );
      }),
    );
  }

  Widget _bookingCard(Map<String, dynamic> b, double textScale) {
    final bookingId = b["bookingId"].toString();
    final services = (b["services"] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        [];

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Booking #$bookingId",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: deepBrown,
                      fontSize: 14 * textScale,
                    ),
                  ),
                ),
                Text(
                  "COMPLETED",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11 * textScale,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (services.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: services
                    .map((s) => Text(
                          s,
                          style: TextStyle(fontSize: 14 * textScale),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 12),
            _starRow(bookingId),
            const SizedBox(height: 12),
            TextField(
              controller: _commentControllers[bookingId],
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Write a comment (optional)",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _allRated(bookingId)
                    ? () => _submitBookingReview(b)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldAccent,
                  foregroundColor: deepBrown,
                ),
                child: const Text("Submit Review"),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.size.width / 390;

    return SafeArea(
      child: Scaffold(
        backgroundColor: crepeBG,
        appBar: AppBar(
          backgroundColor: crepeBG,
          elevation: 0,
          title: const Text(
            "Review Center",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text("Error: $error"))
                : pendingBookings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_border,
                                size: 56, color: Colors.brown),
                            SizedBox(height: 12),
                            Text("No pending reviews",
                                style: TextStyle(fontSize: 16)),
                            SizedBox(height: 6),
                            Text(
                              "You have reviewed all completed bookings",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          itemCount: pendingBookings.length,
                          itemBuilder: (_, i) => _bookingCard(
                              pendingBookings[i], textScale.clamp(0.9, 1.2)),
                        ),
                      ),
      ),
    );
  }
}
