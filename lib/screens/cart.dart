import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // ✅ REQUIRED
import 'bookings.dart';
import 'serviceslist.dart';

class Offer {
  final String offerId;
  final String title;
  final String description;
  final String type;
  final int value;
  final int minAmount;
  final String expiry;

  Offer({
    required this.offerId,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.minAmount,
    required this.expiry,
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
    );
  }

  String get readableExpiry {
    try {
      final d = DateTime.parse(expiry);
      const months = [
        "",
        "Jan","Feb","Mar","Apr","May","Jun",
        "Jul","Aug","Sep","Oct","Nov","Dec"
      ];
      return "${d.day} ${months[d.month]} ${d.year}";
    } catch (_) {
      return expiry;
    }
  }
}

Future<List<Offer>> fetchOffers() async {
  final res = await http.get(
    Uri.parse("https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/offers"),
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return ((data["offers"] ?? []) as List)
        .map((e) => Offer.fromJson(e))
        .toList();
  }
  return [];
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(Map<String, dynamic>) onRemove;
  final bool redeemMode;
  final int availableCoins;

  const CartPage({
    super.key,
    required this.cart,
    required this.onRemove,
    this.redeemMode = false,
    this.availableCoins = 0,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Offer? appliedOffer;
  double backendDiscount = 0;

  int availableCoins = 0;
  int redeemCoinsEntered = 0;
  double redeemDiscount = 0;

  final TextEditingController redeemCtrl = TextEditingController();
  bool _applyingOffer = false;

  @override
  void initState() {
    super.initState();
    widget.redeemMode
        ? availableCoins = widget.availableCoins
        : fetchLatestCoins();
  }

  /// ✅ FIXED — Firebase UID (ONLY REQUIRED CHANGE)
  Future<String> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  Future<void> fetchLatestCoins() async {
    try {
      final userId = await _getUserId();
      final res = await http.post(
        Uri.parse("https://szbj7qys97.execute-api.us-east-1.amazonaws.com/prod/user"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "getCoins", "userId": userId}),
      );

      if (res.statusCode == 200) {
        setState(() {
          availableCoins = jsonDecode(res.body)["coins"] ?? 0;
        });
      }
    } catch (_) {}
  }

  double get subtotal =>
      widget.cart.fold(0, (s, i) => s + (i["cost"] ?? 0).toDouble());

  double get total =>
      (subtotal - backendDiscount - redeemDiscount).clamp(0, double.infinity);

  void applyBeautyCoins() {
    final entered = int.tryParse(redeemCtrl.text.trim()) ?? 0;
    if (entered <= 0) return _msg("Enter valid coins");
    if (entered > availableCoins) return _msg("Not enough coins");

    final rupeeValue = entered / 100;
    if (rupeeValue > subtotal) return _msg("Coins value exceeds subtotal");

    setState(() {
      redeemCoinsEntered = entered;
      redeemDiscount = rupeeValue;
    });
  }

  void _msg(String m) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> applyOffer(Offer offer) async {
    if (_applyingOffer) return; // ✅ BLOCK DOUBLE TAP
    _applyingOffer = true;

    try {
      final res = await http.post(
        Uri.parse("https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/applyOffer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": await _getUserId(),
          "offerId": offer.offerId,
          "cartTotal": subtotal,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["eligible"] == true) {
        setState(() {
          appliedOffer = offer;
          backendDiscount = (data["discountAmount"] ?? 0).toDouble();
        });
        Navigator.pop(context);
        _msg("${offer.title} applied!");
      } else {
        _msg(data["message"] ?? "Not eligible");
      }
    } finally {
      _applyingOffer = false; // ✅ UNLOCK
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE7B872),
        title: const Text(
          "Your Cart",
          style: TextStyle(color: Color(0xFF4A3426)),
        ),
      ),
      body: widget.cart.isEmpty
          ? _emptyCart()
          : SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _cartList(),
                    _couponBar(),
                    const SizedBox(height: 4),
                    _beautyCoinsRedeemBar(),
                    const SizedBox(height: 4),
                    _billSummary(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Text(
                        "Note:\n"
                        "Coins used are non-refundable on cancellation.\n"
                        "100 Beauty Coins are awarded on successful booking and reversed if the booking is cancelled.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: Colors.brown,
                        )
                      )
                    )
                  ],
                ),
              ),
            ),
      bottomNavigationBar:
          widget.cart.isEmpty ? null : _bottomButtons(),
    );
  }

  
  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Your cart is empty"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesListPage()),
              );
            },
            child: const Text("Add Services"),
          )
        ],
      ),
    );
  }

  Widget _cartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.cart.length,
      itemBuilder: (_, i) {
        final item = widget.cart[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(
              "${item["serviceName"]} (${item["gender"]})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "₹${item["cost"]}",
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  widget.cart.remove(item);
                  appliedOffer = null;
                  backendDiscount = 0;
                });
                widget.onRemove(item);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _couponBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8E8D8),
          borderRadius: BorderRadius.circular(16)),
      child: GestureDetector(
        onTap: showCouponsSheet,
        child: Row(
          children: [
            _iconBox(Icons.card_giftcard),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                appliedOffer == null
                    ? "Apply Coupon"
                    : "Applied: ${appliedOffer!.title}",
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  void showCouponsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5DEB3),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) {
        return FutureBuilder<List<Offer>>(
          future: fetchOffers(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final offers = snap.data!;
            offers.sort((a, b) => a.minAmount.compareTo(b.minAmount));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: offers.map(couponTile).toList(),
              ),
            );
          },
        );
      },
    );
  }

  Widget couponTile(Offer offer) {
    final eligible = subtotal >= offer.minAmount;
    return InkWell(
      onTap: () => eligible
          ? applyOffer(offer)
          : _msg("Add ₹${offer.minAmount - subtotal} more to apply"),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.brown.withOpacity(0.15), blurRadius: 6)
            ]),
        child: Row(
          children: [
            Icon(Icons.local_offer,
                color: eligible ? Colors.green : Colors.orange, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offer.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(offer.description,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    eligible ? "Tap to apply" : "Add more items",
                    style: TextStyle(
                        color: eligible ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text("Expires: ${offer.readableExpiry}",
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _beautyCoinsRedeemBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFFF8E8D8),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Redeem Beauty Coins",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Available coins: $availableCoins"),
          const SizedBox(height: 6),
          TextField(
            controller: redeemCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter coins",
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: applyBeautyCoins,
              child: const Text("Apply"),
            ),
          )
        ],
      ),
    );
  }

  Widget _billSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF3E5),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          _billRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
          if (backendDiscount > 0)
            _billRow("Offer Discount",
                "-₹${backendDiscount.toStringAsFixed(0)}",
                color: Colors.green),
          if (redeemDiscount > 0)
            _billRow("Beauty Coins",
                "-₹${redeemDiscount.toStringAsFixed(0)}",
                color: Colors.green),
          const Divider(height: 18),
          _billRow("Grand Total", "₹${total.toStringAsFixed(0)}",
              isBold: true),
        ],
      ),
    );
  }

  Widget _billRow(String title, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.brown)),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.brown)),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ServicesListPage()),
                  );
                },
                child: const Text("Add More"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  redeemDiscount = redeemCoinsEntered / 100;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingPage(
                        cartItems: widget.cart,
                        subtotal: subtotal,
                        couponDiscount: backendDiscount,
                        coinDiscount: redeemDiscount,
                        redeemedCoins: redeemCoinsEntered,
                        total: total,
                      ),
                    ),
                  );
                },
                child: const Text("Book"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.brown, size: 22),
    );
  }
}
