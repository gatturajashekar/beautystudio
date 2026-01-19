import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'cart.dart';
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
}

// ---------------------- API ----------------------
class ApiService {
  static const String baseUrl =
      "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod";

  static Future<List<Offer>> fetchOffers() async {
    final url = Uri.parse("$baseUrl/offers");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data["offers"] ?? [];
      return list.map((e) => Offer.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch offers");
    }
  }
}

// ---------------------- OFFERS PAGE ----------------------
class OffersPage extends StatefulWidget {
  const OffersPage({Key? key}) : super(key: key);

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late Future<List<Offer>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = ApiService.fetchOffers();
  }

  String formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return DateFormat("dd MMM yyyy").format(date);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Offers"),
      ),
      body: FutureBuilder<List<Offer>>(
        future: _offersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
                child: Text("Could not load offers. Try again later."));
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return const Center(child: Text("No offers available"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    _offerImage(offer.imageUrl),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            offer.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Min Order: ₹${offer.minAmount}",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                          Text(
                            "Expiry: ${formatDate(offer.expiry)}",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ----------------------------
                    // UPDATED APPLY BUTTON
                    // ----------------------------
                    ElevatedButton(
                    onPressed: () {
                    Navigator.pushReplacement(
                    context,
                       MaterialPageRoute(
                      builder: (_) => CartPage(
                      cart: [],         // 🔥 Put your actual cart here
                     onRemove: (item) {},
                         ),
                       ),
                      );
                    },
                     style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                       minimumSize: const Size(70, 38),
                        shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
                       ),
                    ),
                      child: const Text("Apply"),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _offerImage(String url) {
    if (url.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.local_offer, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.local_offer, color: Colors.grey),
        ),
      ),
    );
  }
}
