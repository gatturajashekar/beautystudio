// admin_home.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'manageusers.dart';
import 'settings.dart';

const String ADMIN_GET_BOOKINGS_API =
    "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/getBookings";

const String USERS_COUNT_API =
    "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/usersCount";

// REPLACE WITH YOUR FINAL LAMBDA URL:
const String ADMIN_UPDATE_BOOKING_STATUS_API =
    "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/updateStatus";

const crepe = Color(0xFFF5DEB3);
const crepeLight = Color(0xFFFFE8C8);

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool loading = true;
  int totalUsers = 0;

  List<Map<String, dynamic>> upcoming = [];
  List<Map<String, dynamic>> completed = [];
  List<Map<String, dynamic>> cancelled = [];
  List<Map<String, dynamic>> missed = [];

  List<Map<String, dynamic>> todays = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() => loading = true);
    await Future.wait([fetchBookings(), fetchUsersCount()]);
    filterToday();
    setState(() => loading = false);
  }

  Future<void> fetchBookings() async {
    try {
      final res = await http.get(Uri.parse(ADMIN_GET_BOOKINGS_API));
      if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}");

      final data = jsonDecode(res.body);

      List<Map<String, dynamic>> sortList(list) {
        if (list == null) return [];
        List<Map<String, dynamic>> t = List<Map<String, dynamic>>.from(list);
        t.sort((a, b) => (b["timestamp"] ?? 0).compareTo(a["timestamp"] ?? 0));
        return t;
      }

      upcoming = sortList(data["upcoming"] ?? []);
      completed = sortList(data["previous"] ?? []);
      cancelled = sortList(data["cancelled"] ?? []);
      missed = sortList(data["missed"] ?? []);
    } catch (e) {
      upcoming = [];
      completed = [];
      cancelled = [];
      missed = [];
    }
  }

  Future<void> fetchUsersCount() async {
    try {
      final res = await http.get(Uri.parse(USERS_COUNT_API));
      totalUsers = jsonDecode(res.body)["count"] ?? 0;
    } catch (e) {
      totalUsers = 0;
    }
  }

  void filterToday() {
    todays.clear();
    final now = DateTime.now();

    for (var b in [...upcoming, ...completed, ...cancelled, ...missed]) {
      final ts = b["timestamp"];
      if (ts == null) continue;

      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        todays.add(b);
      }
    }
  }

  int get totalBookings =>
      upcoming.length + completed.length + cancelled.length + missed.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: crepe,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadDashboard)
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _wrapStatCard(
                        context,
                        _statCard(
                          title: "Total Users",
                          value: totalUsers.toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ManageUsersPage()),
                            );
                          },
                        ),
                      ),
                      _wrapStatCard(
                        context,
                        _statCard(
                          title: "Total Bookings",
                          value: totalBookings.toString(),
                          icon: Icons.calendar_today,
                          color: Colors.orange,
                          onTap: () {
                            _openHistory(filterTab: 0);
                          },
                        ),
                      ),
                      _wrapStatCard(
                        context,
                        _statCard(
                          title: "Missed",
                          value: missed.length.toString(),
                          icon: Icons.report_problem,
                          color: Colors.grey,
                          onTap: () {
                            _openHistory(filterTab: 3);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _header("Today's Bookings (${todays.length})"),
                  const SizedBox(height: 10),

                  todays.isEmpty
                      ? const Text("No bookings today",
                          style: TextStyle(color: Colors.black54))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todays.length,
                          itemBuilder: (_, i) =>
                              _todayBookingCard(todays[i], context),
                        ),
                ],
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.brown,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
        onTap: (i) {
          if (i == 1) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AdminSettings()));
          }
        },
      ),
    );
  }

  Widget _wrapStatCard(BuildContext context, Widget child) {
    double width = (MediaQuery.of(context).size.width - 20 - 12) / 2;
    return SizedBox(width: width, child: child);
  }

  Widget _header(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _todayBookingCard(Map<String, dynamic> b, BuildContext context) {
    final ts = b["timestamp"];
    final dt = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;

    final time = dt != null
        ? "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}"
        : "N/A";

    final status = _displayStatus(b["status"]);
    final services = (b["services"] is List) ? b["services"] : [];

    return Card(
      color: crepeLight,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        title: Text(b["userName"] ?? "Unknown",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.brown)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: ${b["phone"] ?? "N/A"}"),
            Text("Services: ${services.join(", ")}"),
            Text("Status: $status"),
            Text("Time: $time"),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.brown),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookingDetailsPage(booking: b)),
          );
          if (changed == true) loadDashboard();
        },
      ),
    );
  }

  Widget _statCard(
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _displayStatus(dynamic s) {
    final v = s?.toString().toLowerCase().trim() ?? "";
    if (v == "no_show" || v == "missed") return "MISSED";
    if (v == "completed") return "COMPLETED";
    if (v == "cancelled") return "CANCELLED";
    if (v == "upcoming" || v == "confirmed") return "UPCOMING";
    return v.toUpperCase();
  }

  void _openHistory({int filterTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingsHistoryPage(
          upcoming: upcoming,
          completed: completed,
          cancelled: cancelled,
          missed: missed,
          initialTab: filterTab,
        ),
      ),
    ).then((changed) {
      if (changed == true) loadDashboard();
    });
  }
}

// ---------------- HISTORY PAGE ----------------
class BookingsHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> upcoming;
  final List<Map<String, dynamic>> completed;
  final List<Map<String, dynamic>> cancelled;
  final List<Map<String, dynamic>> missed;
  final int initialTab;

  const BookingsHistoryPage({
    super.key,
    required this.upcoming,
    required this.completed,
    required this.cancelled,
    required this.missed,
    required this.initialTab,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: crepe,
        appBar: AppBar(
          backgroundColor: Colors.brown,
          title: const Text("All Bookings"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Completed"),
              Tab(text: "Cancelled"),
              Tab(text: "Missed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(upcoming, context),
            _buildList(completed, context),
            _buildList(cancelled, context),
            _buildList(missed, context),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, BuildContext ctx) {
    if (list.isEmpty) {
      return const Center(child: Text("No bookings"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final b = list[i];
        final ts = b["timestamp"];
        String when = "N/A";

        if (ts != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(ts);
          when =
              "${dt.day}-${dt.month}-${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
        }

        return Card(
          color: crepeLight,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(b["userName"] ?? "Unknown",
                style: const TextStyle(color: Colors.brown)),
            subtitle: Text(when),
            trailing: const Icon(Icons.chevron_right, color: Colors.brown),
            onTap: () async {
              final changed = await Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => BookingDetailsPage(booking: b)),
              );
              if (changed == true) Navigator.pop(ctx, true);
            },
          ),
        );
      },
    );
  }
}

// ---------------- BOOKING DETAILS ----------------
class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool working = false;

  bool get canMarkComplete {
    final raw = widget.booking["status"]?.toString().toLowerCase().trim() ?? "";
    return raw == "upcoming" || raw == "confirmed";
  }

  String _displayStatus(dynamic s) {
    final v = s?.toString().toLowerCase().trim() ?? "";
    if (v == "no_show" || v == "missed") return "MISSED";
    if (v == "completed") return "COMPLETED";
    if (v == "cancelled") return "CANCELLED";
    if (v == "upcoming" || v == "confirmed") return "UPCOMING";
    return v.toUpperCase();
  }

  Future<void> markCompleted() async {
    if (!canMarkComplete) return;

    final userId = widget.booking["userId"];
    final bookingId = widget.booking["bookingId"];

    setState(() => working = true);

    try {
      final res = await http.post(
        Uri.parse(ADMIN_UPDATE_BOOKING_STATUS_API),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "bookingId": bookingId,
          "status": "completed"
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Booking marked completed")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed ${res.statusCode}: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final dt = b["timestamp"] != null
        ? DateTime.fromMillisecondsSinceEpoch(b["timestamp"])
        : null;

    final services = (b["services"] is List) ? b["services"] : [];

    return Scaffold(
      backgroundColor: crepe,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text("Booking Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("User Information",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const SizedBox(height: 6),
            Text("Name: ${b["userName"] ?? "N/A"}"),
            Text("Phone: ${b["phone"] ?? "N/A"}"),

            const SizedBox(height: 20),
            Text("Booking Information",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child:
                      Text("Status: ${_displayStatus(b["status"])}"),
                ),

                if (canMarkComplete)
                  ElevatedButton(
                    onPressed: working ? null : markCompleted,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: working
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Complete"),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            Text("Date: ${dt != null ? "${dt.day}-${dt.month}-${dt.year}" : "N/A"}"),
            Text("Time: ${dt != null ? "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}" : "N/A"}"),

            const SizedBox(height: 20),
            Text("Services",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const SizedBox(height: 6),

            ...services
                .map((s) => Text("• $s", style: const TextStyle(fontSize: 15)))
                .toList(),

            const SizedBox(height: 20),
            Text("Billing",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            Text("Amount: ₹${b["totalAmount"] ?? 0}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
