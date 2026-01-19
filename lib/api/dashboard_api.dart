import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardAPI {
  static const String baseUrl =
      "https://z3fuwa8f6j.execute-api.us-east-1.amazonaws.com/prod";

  // ✅ Corrected static constants
  static const String GET_SERVICES_URL =
      "$baseUrl/getServices";

  static const String GET_BOOKINGS_URL =
      "$baseUrl/getBookings";

  static const String CANCEL_BOOKING_URL =
      "https://cb1c5ts2z1.execute-api.us-east-1.amazonaws.com/cancelBooking";

  // ------------------ DASHBOARD DATA -------------------
  static Future<Map<String, dynamic>> getDashboardData(String userId) async {
    final url = Uri.parse("$baseUrl/dashboard?userId=$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load dashboard data: ${response.body}");
    }
  }
}
