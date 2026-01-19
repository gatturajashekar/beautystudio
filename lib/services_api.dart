import 'dart:convert';
import 'package:http/http.dart' as http;

class ServicesApi {
  // =====================================================
  // SERVICES
  // =====================================================

  static final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  static bool _loadingServices = false;

  static Future<List<Map<String, dynamic>>> getServicesByCategory(
      String category) async {
    if (_servicesByCategory.containsKey(category)) {
      return _servicesByCategory[category]!;
    }

    if (_loadingServices) return [];

    _loadingServices = true;
    try {
      final res = await http.get(
        Uri.parse(
          "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/prod/getServices?category=$category",
        ),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        final services = decoded.map<Map<String, dynamic>>((item) {
          return {
            "serviceName": item["serviceName"] ?? "",
            "category": item["category"] ?? "",
            "description": item["description"] ?? "",
            "gender": item["gender"] ?? "",
            "cost": item["cost"] ?? 0,
          };
        }).toList();

        _servicesByCategory[category] = services;
        return services;
      }
    } finally {
      _loadingServices = false;
    }

    return [];
  }
// =====================================================
// GALLERY (FINAL & CORRECT)
// =====================================================

static List<String> _galleryPhotos = [];
static List<Map<String, dynamic>> _galleryVideos = [];
static bool _loadingGallery = false;

static Future<void> loadGallery() async {
  if (_loadingGallery) return;
  _loadingGallery = true;

  try {
    final res = await http.get(
      Uri.parse(
        "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/images/gallery",
      ),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      _galleryPhotos = List<String>.from(data["photos"] ?? []);
      _galleryVideos =
          List<Map<String, dynamic>>.from(data["videos"] ?? []);
    } else {
      _galleryPhotos = [];
      _galleryVideos = [];
    }
  } catch (_) {
    _galleryPhotos = [];
    _galleryVideos = [];
  } finally {
    _loadingGallery = false;
  }
}

static List<String> getGalleryPhotos() => _galleryPhotos;
static List<Map<String, dynamic>> getGalleryVideos() => _galleryVideos;


  // =====================================================
  // BOOKINGS
  // =====================================================

  static List<Map<String, dynamic>>? _cachedBookings;

  static Future<List<Map<String, dynamic>>> getBookings(
    String userId,
    Map<String, String> headers,
  ) async {
    if (_cachedBookings != null) return _cachedBookings!;

    final res = await http.get(
      Uri.parse(
        "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/getBookings?userId=$userId",
      ),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final decoded = jsonDecode(res.body);
    final List<Map<String, dynamic>> list = [];

    for (final k in ["upcoming", "completed", "cancelled", "missed"]) {
      if (decoded[k] is List) {
        list.addAll(List<Map<String, dynamic>>.from(decoded[k]));
      }
    }

    _cachedBookings = list;
    return list;
  }

  static Future<void> cancelBooking(
    String userId,
    String bookingId,
    Map<String, String> headers,
  ) async {
    final res = await http.post(
      Uri.parse(
        "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/cancelBooking",
      ),
      headers: headers,
      body: jsonEncode({
        "userId": userId,
        "bookingId": bookingId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    _cachedBookings = null;
  }

  // =====================================================
  // OFFERS
  // =====================================================

  static List<Map<String, dynamic>>? _cachedOffers;

  static Future<List<Map<String, dynamic>>> getOffers() async {
    if (_cachedOffers != null) return _cachedOffers!;

    final res = await http.get(
      Uri.parse(
        "https://szbj7qys97.execute-api.us-east-1.amazonaws.com/prod/offers",
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final decoded = jsonDecode(res.body);
    _cachedOffers = List<Map<String, dynamic>>.from(decoded["offers"] ?? []);
    return _cachedOffers!;
  }

  // =====================================================
  // COINS
  // =====================================================

  static int? _cachedCoins;

  static Future<int> getCoins(String userId) async {
    if (_cachedCoins != null) return _cachedCoins!;

    final res = await http.post(
      Uri.parse(
        "https://szbj7qys97.execute-api.us-east-1.amazonaws.com/prod/user",
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "action": "getCoins",
        "userId": userId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body);
    _cachedCoins = data["coins"] ?? 0;
    return _cachedCoins!;
  }

  // =====================================================
  // RESET
  // =====================================================

  static void clearAll() {
    _servicesByCategory.clear();
    _galleryPhotos.clear();
    _galleryVideos.clear();
    _cachedBookings = null;
    _cachedOffers = null;
    _cachedCoins = null;
  }
}
