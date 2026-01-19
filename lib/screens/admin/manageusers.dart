import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// =====================================================
// SAFE PARSERS
// =====================================================

String toStr(Map m, String k) => (m[k] ?? "").toString();

int toInt(Map m, String k) =>
    int.tryParse((m[k] ?? "0").toString()) ?? 0;

double toDoubleVal(Map m, String k) =>
    double.tryParse((m[k] ?? "0").toString()) ?? 0.0;

// =====================================================
// MANAGE USERS PAGE
// =====================================================

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final String apiUrl =
      "https://4o5flfa5w0.execute-api.us-east-1.amazonaws.com/prod/users";

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> view = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final res =
          await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception("HTTP ${res.statusCode}");

      final body = jsonDecode(res.body);
      users =
          (body["users"] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      view = List.from(users);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    setState(() => loading = false);
  }

  void search(String q) {
    final t = q.toLowerCase();
    view = users.where((u) {
      return toStr(u, "name").toLowerCase().contains(t) ||
          toStr(u, "phone").toLowerCase().contains(t);
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        onChanged: search,
                        decoration: InputDecoration(
                          hintText: "Search by name or phone",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: view.length,
                        itemBuilder: (_, index) {
                          final u = view[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    toStr(u, "name").isEmpty
                                        ? "Unnamed User"
                                        : toStr(u, "name"),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (toStr(u, "phone").isNotEmpty)
                                    Text("📞 ${toStr(u, "phone")}"),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  UserDetailsPage(user: u),
                                            ),
                                          );
                                        },
                                        child: const Text("User Details"),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserBookingsPage(
                                                userId: toStr(u, "userId"),
                                                userName: toStr(u, "name"),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text("View Bookings"),
                                      ),
                                    ],
                                  )
                                ],
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

// =====================================================
// USER DETAILS PAGE
// =====================================================

class UserDetailsPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailsPage({super.key, required this.user});

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isEmpty ? "-" : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = toStr(user, "userId");

    return Scaffold(
      appBar: AppBar(title: const Text("User Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row("User ID", userId),
                  row("Name", toStr(user, "name")),
                  row("Phone", toStr(user, "phone")),
                  row("Gender", toStr(user, "gender")),
                  row("Age", toInt(user, "age").toString()),
                  row("Address", toStr(user, "address")),
                  row("Coins", toInt(user, "coins").toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserBookingsPage(
                    userId: userId,
                    userName: toStr(user, "name"),
                  ),
                ),
              );
            },
            child: const Text("View Bookings"),
          )
        ],
      ),
    );
  }
}

// =====================================================
// USER BOOKINGS PAGE WITH FILTERS
// =====================================================

const String ADMIN_GET_BOOKINGS_API =
    "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/admin/getBookings";

class UserBookingsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserBookingsPage(
      {super.key, required this.userId, required this.userName});

  @override
  State<UserBookingsPage> createState() => _UserBookingsPageState();
}

class _UserBookingsPageState extends State<UserBookingsPage> {
  bool loading = true;
  List<Map<String, dynamic>> allBookings = [];
  List<Map<String, dynamic>> visible = [];
  String filter = "all";

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    try {
      final res = await http.get(Uri.parse(ADMIN_GET_BOOKINGS_API));
      if (res.statusCode != 200) throw Exception();

      final data = jsonDecode(res.body);
      final all = [
        ...(data["upcoming"] ?? []),
        ...(data["previous"] ?? []),
        ...(data["cancelled"] ?? []),
        ...(data["missed"] ?? []),
      ];

      allBookings = all
          .where((b) => toStr(b, "userId") == widget.userId)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      applyFilter("all");
    } catch (_) {
      allBookings = [];
      visible = [];
    }

    setState(() => loading = false);
  }

  void applyFilter(String f) {
    filter = f;
    if (f == "all") {
      visible = List.from(allBookings);
    } else {
      visible =
          allBookings.where((b) => toStr(b, "status") == f).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.userName} – Bookings")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Bookings: ${allBookings.length}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final f in [
                            "all",
                            "upcoming",
                            "completed",
                            "cancelled",
                            "missed"
                          ])
                            ChoiceChip(
                              label: Text(f.toUpperCase()),
                              selected: filter == f,
                              onSelected: (_) => applyFilter(f),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text("No bookings found"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: visible.length,
                          itemBuilder: (_, index) {
                            final b = visible[index];
                            final ts = b["timestamp"];
                            String dt = "N/A";
                            if (ts is int) {
                              final d =
                                  DateTime.fromMillisecondsSinceEpoch(ts);
                              dt =
                                  "${d.day}-${d.month}-${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
                            }

                            return Card(
                              child: ListTile(
                                title: Text(
                                    "Booking ${toStr(b, "bookingId")}"),
                                subtitle: Text(
                                    "${toStr(b, "status").toUpperCase()}\n$dt"),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookingDetailsPage(booking: b),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
    );
  }
}

// =====================================================
// BOOKING DETAILS PAGE
// =====================================================

class BookingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final services =
        (booking["services"] as List?)?.cast<String>() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Booking ID: ${toStr(booking, "bookingId")}"),
                  Text("Status: ${toStr(booking, "status")}"),
                  Text("Date: ${toStr(booking, "date")}"),
                  Text("Time: ${toStr(booking, "time")}"),
                  Text(
                      "Total Amount: ₹${toDoubleVal(booking, "totalAmount")}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Services",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...services.map((s) => Text("• $s")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
