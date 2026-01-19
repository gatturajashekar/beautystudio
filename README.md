# Beautystudio

Beautystudio is a real-world Flutter mobile application built for a single beauty salon to manage customer appointments, services, offers, and loyalty rewards through a customer app and an admin panel.

The app is designed to reduce manual booking, phone-call dependency, and in-salon confusion by providing a simple digital booking experience for customers and clear tracking tools for the salon manager.

---

## Key Features

### Customer Features
- Browse available salon services
- Apply offers or BeautyCoins during booking
- Select preferred date and time slots
- Instant booking confirmation if slots are available
- Slot availability check (full slots are clearly indicated)
- Cancel bookings (rescheduling not supported)
- Click-to-call salon directly from the app
- WhatsApp chat integration via deep link
- View offers and loyalty rewards

### Admin (Salon Manager) Features
- View all bookings
- View today’s bookings
- Mark bookings as completed
- View registered users
- View total bookings count
- View total offers
- View total customer ratings

---

## Booking Flow
1. Select a service
2. Apply available offers or BeautyCoins
3. Choose date and time
4. Confirm booking  
   - Instant confirmation if slot is available  
   - Slot marked as full if unavailable

Customers can cancel bookings but cannot reschedule them.

---

## BeautyCoins (Loyalty System)
- +100 BeautyCoins for every successful booking
- +1000 BeautyCoins for every successful referral
- -100 BeautyCoins for booking cancellation
- -100 BeautyCoins for missed bookings

> Currently, BeautyCoins are displayed with a low monetary value  
> (e.g., 100 coins ≈ ₹1).  
> Full wallet-based redemption is planned for later versions.

---

## Offers & Promotions
- Offers are added directly by the salon owner via the backend
- Admin (manager) can view total offers
- Supports:
  - Time-based offers
  - Festival offers
  - Fixed promotional offers

---

## Communication
- One-tap phone call using device dialer
- WhatsApp deep link connected directly to the salon’s number
- Reduces customer queries and walk-in confusion

---

## Authentication & Roles
- **Customers:** Phone number + OTP login
- **Admin (Salon Manager):** Email & password login
- Role-based access controls admin features

---

## Tech Stack
- Flutter (Dart) — frontend
- Firebase Authentication — user login & OTP
- Firebase Cloud Messaging — notifications
- AWS  — backend services
- Android & iOS platforms

---

## Project Status
**Ready for launch**  
The app is built for real salon usage and will be published soon on **Android and iOS**.

---

## Notes
This project represents a real business use case and demonstrates end-to-end mobile app development, backend integration, role-based access, and loyalty system design.
