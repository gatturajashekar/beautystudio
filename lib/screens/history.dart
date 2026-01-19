import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services_api.dart';

const bool devMode = false;
const String devUserId = "DEV_USER_001";

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool loading = true;
  String? errorMessage;

  List<Map<String, dynamic>> allBookings = [];
  List<Map<String, dynamic>> filteredBookings = [];

  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final userId = await _getUserId();
      final headers = await _authHeaders();

      allBookings = await ServicesApi.getBookings(userId, headers);
      _applyFilter();
    } catch (e) {
      errorMessage = e.toString();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _applyFilter() {
    if (selectedFilter == "All") {
      filteredBookings = List.from(allBookings);
    } else {
      filteredBookings = allBookings.where((b) {
        final raw = b["status"]?.toString().toLowerCase().trim() ?? "";
        return raw == selectedFilter.toLowerCase();
      }).toList();
    }
    setState(() {});
  }

  /// ✅ Firebase UID (correct way)
  Future<String> _getUserId() async {
    if (devMode) return devUserId;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  /// ✅ No token needed (Firebase-secured backend)
  Future<Map<String, String>> _authHeaders() async {
    return {"Content-Type": "application/json"};
  }

  DateTime? _parseTimestamp(dynamic ts) {
    try {
      if (ts == null) return null;
      final value = ts is int ? ts : int.tryParse(ts.toString());
      if (value == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }

  String formatTimestamp(dynamic ts) {
    final dt = _parseTimestamp(ts);
    if (dt == null) return "Unknown Date";
    return DateFormat.yMMMMd().add_jm().format(dt);
  }

  Future<void> cancelBooking(String bookingId) async {
    final userId = await _getUserId();
    final headers = await _authHeaders();

    try {
      await ServicesApi.cancelBooking(userId, bookingId, headers);
      await _loadAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking cancelled")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget bookingCard(Map b) {
    final rawStatus =
        b["status"]?.toString().toLowerCase().trim() ?? "unknown";

    final validStatuses = ["upcoming", "completed", "cancelled", "missed"];
    final status =
        validStatuses.contains(rawStatus) ? rawStatus : "unknown";

    final badgeColors = {
      "upcoming": Colors.orange,
      "completed": Colors.green,
      "cancelled": Colors.red,
      "missed": Colors.grey,
      "unknown": Colors.black54,
    };

    final ts = _parseTimestamp(b["timestamp"]);
    final services = (b["services"] ?? []) as List;

    final canCancel =
        status == "upcoming" && ts != null && ts.isAfter(DateTime.now());

    final subtotal = b["subtotal"] ?? 0;
    final discount = b["discount"] ?? 0;
    final coinDiscount = b["coinDiscount"] ?? 0;
    final couponDiscount = b["couponDiscount"] ?? 0;

    final total = (subtotal as num) -
        (discount as num) -
        (coinDiscount as num) -
        (couponDiscount as num);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(1, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Booking #${b["bookingId"] ?? "N/A"}",
                  style: const TextStyle(
                      color: Colors.brown,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: badgeColors[status]!.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22)),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                      color: badgeColors[status],
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),

          const SizedBox(height: 12),

          if (services.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: services
                  .map((s) => Row(
                        children: [
                          const Icon(Icons.check,
                              size: 16, color: Colors.brown),
                          const SizedBox(width: 6),
                          Text(s.toString()),
                        ],
                      ))
                  .toList(),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 18, color: Colors.brown),
              const SizedBox(width: 6),
              Text(formatTimestamp(b["timestamp"]),
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                rowText("Subtotal", "₹$subtotal"),
                rowText("Discount", "- ₹$discount"),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("₹$total",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (canCancel)
            TextButton(
              onPressed: () async {
                final yes = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Cancel Booking?"),
                    content: const Text(
                        "Are you sure you want to cancel this booking?"),
                    actions: [
                      TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text("No")),
                      ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text("Yes"))
                    ],
                  ),
                );

                if (yes == true) {
                  cancelBooking(b["bookingId"]);
                }
              },
              child: const Text("Cancel Booking",
                  style: TextStyle(color: Colors.red)),
            )
        ],
      ),
    );
  }

  Widget rowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4E2D8),
        elevation: 0,
        title: const Text("My Bookings",
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text("Error: $errorMessage"))
              : Column(
                  children: [
                    /// ✅ FILTER UI RESTORED (UNCHANGED)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: DropdownButtonFormField<String>(
                        value: selectedFilter,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "Filter",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          "All",
                          "upcoming",
                          "completed",
                          "cancelled",
                          "missed"
                        ].map((f) {
                          return DropdownMenuItem(
                              value: f, child: Text(f.toUpperCase()));
                        }).toList(),
                        onChanged: (v) {
                          selectedFilter = v!;
                          _applyFilter();
                        },
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAll,
                        child: filteredBookings.isEmpty
                            ? const Center(
                                child: Text("No bookings found",
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54)))
                            : ListView.builder(
                                itemCount: filteredBookings.length,
                                itemBuilder: (_, i) =>
                                    bookingCard(filteredBookings[i]),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
