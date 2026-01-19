import 'package:flutter/material.dart';

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = [
      {"userName": "Alice", "service": "Haircut", "date": "2025-10-24", "status": "Pending"},
      {"userName": "Bob", "service": "Manicure", "date": "2025-10-25", "status": "Confirmed"},
      {"userName": "Charlie", "service": "Spa", "date": "2025-10-26", "status": "Completed"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('${b['userName']} - ${b['service']}'),
              subtitle: Text('Date: ${b['date']} | Status: ${b['status']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  // For UI demo, we just show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${b['userName']} marked $value')),
                  );
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Confirmed', child: Text('Confirm')),
                  PopupMenuItem(value: 'Cancelled', child: Text('Cancel')),
                  PopupMenuItem(value: 'Completed', child: Text('Complete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
