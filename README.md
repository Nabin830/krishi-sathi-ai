# Krishi Sathi AI 🌱

Krishi Sathi AI is a smart farming support app made to help farmers check crop problems, get weather advice, save market prices, sell crops, and manage farm information from one simple mobile app.

The app is built with Flutter and Firebase.

---

## Main Features

### Login and Signup

Users can create an account using email and password. Existing users can login securely using Firebase Authentication.

### Crop Disease Check

Farmers can select or take a plant photo and add symptoms or notes. The app gives simple AI-style crop guidance based on the note and selected symptoms. Reports are saved in Firebase Firestore.

### My Crop Reports

Farmers can view their submitted crop problem reports. They can check report status, AI guidance, expert review, severity, urgency, and treatment advice.

### Admin Crop Report Review

Admin users can review crop reports submitted by farmers. Admin can update plant name, affected part, possible problem, severity, urgency, treatment steps, prevention tips, and expert comments.

### Weather Advice

Farmers can search places and check weather information including temperature, humidity, rain chance, wind speed, and forecast. The app gives simple farming advice based on the weather.

### Weather History

Saved AI weather advice can be viewed later. Farmers can search previous weather advice by crop, place, risk, or advice.

### Market Prices

Farmers can add local market prices for crops. The app can compare saved market price records and show whether the price is high, low, or close to average.

### Market Price History

Farmers can view and manage saved market price history.

### Sell Crops

Farmers can create crop listings with crop name, quantity, price, quality, location, contact number, and notes.

### Marketplace

Buyers can view active crop listings and contact sellers directly.

### My Listings

Farmers can manage their own crop listings. They can mark listings as active, sold, or inactive. They can also delete listings.

### Admin Listings

Admin users can view and manage all crop listings.

### Notifications

Farmers can receive notifications, for example when their crop report is reviewed by admin.

### Farmer Profile

Farmers can save profile details such as full name, phone number, district, municipality, main crop, and farm size.

### Language Support

The app supports English and Nepali language switching.

---

## Technologies Used

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Shared Preferences
- Image Picker
- Geolocator
- Geocoding
- HTTP package
- Open-Meteo Weather API

---

## Project Structure

Main project files are inside the `lib` folder.

```text
lib/
├── main.dart
├── firebase_options.dart
├── app_language.dart
├── login_screen.dart
├── home_screen.dart
├── settings_screen.dart
├── profile_screen.dart
├── crop_disease_screen.dart
├── my_crop_reports_screen.dart
├── crop_report_detail_screen.dart
├── admin_reports_screen.dart
├── admin_report_detail_screen.dart
├── ai_diagnosis_service.dart
├── ai_backend_service.dart
├── image_upload_service.dart
├── weather_service.dart
├── weather_advice_screen.dart
├── weather_ai_service.dart
├── weather_ai_history_screen.dart
├── weather_firestore_service.dart
├── market_price_screen.dart
├── market_price_history_screen.dart
├── sell_crop_screen.dart
├── buyer_market_screen.dart
├── my_listings_screen.dart
├── admin_listings_screen.dart
├── notification_screen.dart
├── backend_config.dart
└── backend_status_screen.dart