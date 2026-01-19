import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'homescreen.dart';

const String CREATE_BOOKING_URL =
    "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/prod/createBooking";

const String GET_SLOTS_URL =
    "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/prod/getSlots";

class BookingPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double couponDiscount;
  final double coinDiscount;
  final double total;
  final String? appliedOfferId;
  final int redeemedCoins;

  const BookingPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.couponDiscount,
    required this.coinDiscount,
    required this.redeemedCoins,
    required this.total,
    this.appliedOfferId,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  /// slots -> booked count
  Map<String, int> slotCounts = {};

  /// MUST MATCH BACKEND
  final int maxSlots = 4;

  final List<String> allSlots = [
    "09:00","09:30","10:00","10:30","11:00","11:30",
    "12:00","12:30","13:00","13:30","14:00","14:30",
    "15:00","15:30","16:00","16:30","17:00","17:30",
    "18:00","18:30","19:00","19:30","20:00",
  ];

  List<String> morningSlots = [];
  List<String> afternoonSlots = [];
  List<String> eveningSlots = [];

  @override
  void initState() {
    super.initState();
    _divideTimeSlots();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      slotCounts = {}; // ✅ clear old data
    });

    final formattedDate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    final uri = Uri.parse("$GET_SLOTS_URL?date=$formattedDate");

    final response = await http.get(uri);
    if (response.statusCode != 200) return;

    final decoded = jsonDecode(response.body);
    final raw = decoded["slots"];

    if (raw is Map) {
      final parsed = <String, int>{};
      raw.forEach((k, v) {
        final n = int.tryParse(v.toString());
        if (n != null) parsed[k] = n;
      });
      setState(() => slotCounts = parsed);
    }
  }

  void _divideTimeSlots() {
    morningSlots = allSlots.where((s) => int.parse(s.split(":")[0]) < 12).toList();
    afternoonSlots = allSlots
        .where((s) {
          final h = int.parse(s.split(":")[0]);
          return h >= 12 && h < 17;
        })
        .toList();
    eveningSlots = allSlots.where((s) => int.parse(s.split(":")[0]) >= 17).toList();
  }

  TimeOfDay _toTime(String t) {
    final p = t.split(":");
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  Future<void> _saveBookingToLambda() async {
    if (_selectedTime == null) {
      throw Exception("Time slot not selected");
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final formattedDate = DateFormat("yyyy-MM-dd").format(_selectedDate);
    final formattedTime =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

    final services = widget.cartItems.map((item) {
      final name = item["serviceName"] ?? item["service_name"] ?? "";
      final gender = item["gender"] ?? "";
      return gender.toString().isNotEmpty ? "$name ($gender)" : name.toString();
    }).toList();

    final body = {
      "userId": user.uid,
      "phone": user.phoneNumber ?? "",
      "services": services,
      "date": formattedDate,
      "time": formattedTime,
      "subtotal": widget.subtotal,
      "couponDiscount": widget.couponDiscount,
      "coinDiscount": widget.coinDiscount,
      "redeemedCoins": widget.redeemedCoins,
      "totalAmount": widget.total,
    };

    final res = await http.post(
      Uri.parse(CREATE_BOOKING_URL),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  void _confirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select a time slot")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _saveBookingToLambda();
      widget.cartItems.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Booking successful")));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTimeSection(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final booked = slotCounts[slot] ?? 0;
            final isFull = booked >= maxSlots;

            final now = DateTime.now();
            final t = _toTime(slot);
            final pastToday =
                DateUtils.isSameDay(_selectedDate, now) &&
                (t.hour < now.hour ||
                    (t.hour == now.hour && t.minute <= now.minute));

            final disabled = isFull || pastToday;
            final selected =
                _selectedTime?.hour == t.hour && _selectedTime?.minute == t.minute;

            return GestureDetector(
              onTap: disabled ? null : () => setState(() => _selectedTime = t),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: disabled
                      ? Colors.grey.shade300
                      : selected
                          ? Colors.orangeAccent
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: disabled ? Colors.grey : Colors.black),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    color: disabled ? Colors.grey : Colors.black,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildCalendar() {
    final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat("MMMM yyyy").format(_selectedDate),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            itemBuilder: (_, i) {
              final d = days[i];
              final selected = DateUtils.isSameDay(d, _selectedDate);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = d;
                    _selectedTime = null;
                  });
                  _loadSlots();
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? Colors.orangeAccent : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat("E").format(d)),
                      const SizedBox(height: 4),
                      Text(d.day.toString(),
                          style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDD0),
      appBar: AppBar(
        title: const Text("Select Date & Time"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendar(),
            const SizedBox(height: 25),
            _buildTimeSection("Morning", morningSlots),
            const SizedBox(height: 20),
            _buildTimeSection("Afternoon", afternoonSlots),
            const SizedBox(height: 20),
            _buildTimeSection("Evening", eveningSlots),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Confirm Booking"),
                  ),
          ],
        ),
      ),
    );
  }
}
