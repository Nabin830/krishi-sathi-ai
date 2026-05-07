import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'weather_ai_service.dart';
import 'weather_service.dart';

class WeatherFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> saveAiWeatherAdvice({
    required String cropName,
    required String cropNameNe,
    required WeatherResult weather,
    required WeatherAiResult aiResult,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    await _firestore.collection('weatherAiHistory').add({
      'userId': user.uid,
      'userEmail': user.email,

      'cropName': cropName,
      'cropNameNe': cropNameNe,

      'placeName': weather.place.displayName,
      'placeCountry': weather.place.country,
      'placeAdmin1': weather.place.admin1,
      'latitude': weather.place.latitude,
      'longitude': weather.place.longitude,

      'temperature': weather.temperatureText,
      'humidity': weather.humidityText,
      'rainChance': weather.rainChanceText,
      'windSpeed': weather.windText,
      'weatherType': weather.weatherType,
      'weatherTypeNe': weather.weatherTypeNe,

      'aiWeatherTitle': aiResult.aiWeatherTitle,
      'aiWeatherTitleNe': aiResult.aiWeatherTitleNe,
      'aiWeatherSummary': aiResult.aiWeatherSummary,
      'aiWeatherSummaryNe': aiResult.aiWeatherSummaryNe,
      'aiWeatherRisk': aiResult.aiWeatherRisk,
      'aiWeatherRiskNe': aiResult.aiWeatherRiskNe,
      'aiWeatherActions': aiResult.aiWeatherActions,
      'aiWeatherActionsNe': aiResult.aiWeatherActionsNe,

      'weatherAiStatus': aiResult.weatherAiStatus,
      'weatherAiMessage': aiResult.weatherAiMessage,
      'weatherAiMessageNe': aiResult.weatherAiMessageNe,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
