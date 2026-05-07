import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherPlace {
  final String name;
  final String country;
  final String admin1;
  final double latitude;
  final double longitude;

  WeatherPlace({
    required this.name,
    required this.country,
    required this.admin1,
    required this.latitude,
    required this.longitude,
  });

  String get displayName {
    final parts = <String>[];

    if (name.trim().isNotEmpty) parts.add(name.trim());
    if (admin1.trim().isNotEmpty) parts.add(admin1.trim());
    if (country.trim().isNotEmpty) parts.add(country.trim());

    return parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'admin1': admin1,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory WeatherPlace.fromJson(Map<String, dynamic> json) {
    return WeatherPlace(
      name: (json['name'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      admin1: (json['admin1'] ?? '').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class DailyWeather {
  final String date;
  final double maxTemp;
  final double minTemp;
  final int rainChance;
  final int weatherCode;

  DailyWeather({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rainChance,
    required this.weatherCode,
  });

  String get maxTempText => '${maxTemp.round()}°C';
  String get minTempText => '${minTemp.round()}°C';
  String get rainChanceText => '$rainChance%';

  String get dayLabel {
    final today = DateTime.now();
    final dateTime = DateTime.tryParse(date);

    if (dateTime == null) return date;

    final difference = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[dateTime.weekday - 1];
  }

  String get dayLabelNe {
    final today = DateTime.now();
    final dateTime = DateTime.tryParse(date);

    if (dateTime == null) return date;

    final difference = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;

    if (difference == 0) return 'आज';
    if (difference == 1) return 'भोलि';

    const days = [
      'सोमबार',
      'मंगलबार',
      'बुधबार',
      'बिहीबार',
      'शुक्रबार',
      'शनिबार',
      'आइतबार',
    ];

    return days[dateTime.weekday - 1];
  }

  String get weatherType {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode == 1 || weatherCode == 2) return 'Partly cloudy';
    if (weatherCode == 3) return 'Cloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rainy';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snowy';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Unknown';
  }

  String get weatherTypeNe {
    if (weatherCode == 0) return 'सफा मौसम';
    if (weatherCode == 1 || weatherCode == 2) return 'आंशिक बादल';
    if (weatherCode == 3) return 'बादल लागेको';
    if (weatherCode == 45 || weatherCode == 48) return 'कुहिरो';
    if (weatherCode >= 51 && weatherCode <= 67) return 'पानी पर्ने';
    if (weatherCode >= 71 && weatherCode <= 77) return 'हिउँ पर्ने';
    if (weatherCode >= 80 && weatherCode <= 82) return 'वर्षा हुने';
    if (weatherCode >= 95) return 'चट्याङ/आँधी';
    return 'थाहा छैन';
  }

  bool get isHot => maxTemp >= 30;
  bool get isCold => minTemp <= 12;
  bool get isRainy =>
      rainChance >= 60 ||
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 82) ||
      weatherCode >= 95;

  String get farmerAdviceEn {
    if (isRainy) {
      return 'Rain risk is high. Avoid spraying and check field drainage.';
    }

    if (isHot) {
      return 'Hot day expected. Water early morning or late afternoon.';
    }

    if (isCold) {
      return 'Cold condition expected. Protect young or sensitive plants.';
    }

    return 'Weather looks manageable. Continue normal crop monitoring.';
  }

  String get farmerAdviceNe {
    if (isRainy) {
      return 'पानी पर्ने जोखिम धेरै छ। छर्कने काम नगर्नुहोस् र खेतको निकास जाँच गर्नुहोस्।';
    }

    if (isHot) {
      return 'तातो दिन हुने सम्भावना छ। बिहान वा साँझ पानी दिनुहोस्।';
    }

    if (isCold) {
      return 'चिसो अवस्था हुन सक्छ। साना वा संवेदनशील बिरुवालाई जोगाउनुहोस्।';
    }

    return 'मौसम सामान्य देखिन्छ। बाली नियमित जाँच गर्दै जानुहोस्।';
  }
}

class WeatherResult {
  final WeatherPlace place;
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final double precipitation;
  final int rainChance;
  final List<DailyWeather> forecast;

  WeatherResult({
    required this.place,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.precipitation,
    required this.rainChance,
    List<DailyWeather>? forecast,
  }) : forecast = forecast ?? const [];

  String get temperatureText => '${temperature.round()}°C';
  String get humidityText => '$humidity%';
  String get windText => '${windSpeed.toStringAsFixed(1)} km/h';
  String get rainChanceText => '$rainChance%';

  String get weatherType {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode == 1 || weatherCode == 2) return 'Partly cloudy';
    if (weatherCode == 3) return 'Cloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rainy';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snowy';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Unknown';
  }

  String get weatherTypeNe {
    if (weatherCode == 0) return 'सफा मौसम';
    if (weatherCode == 1 || weatherCode == 2) return 'आंशिक बादल';
    if (weatherCode == 3) return 'बादल लागेको';
    if (weatherCode == 45 || weatherCode == 48) return 'कुहिरो';
    if (weatherCode >= 51 && weatherCode <= 67) return 'पानी पर्ने';
    if (weatherCode >= 71 && weatherCode <= 77) return 'हिउँ पर्ने';
    if (weatherCode >= 80 && weatherCode <= 82) return 'वर्षा हुने';
    if (weatherCode >= 95) return 'चट्याङ/आँधी';
    return 'थाहा छैन';
  }

  bool get isHot => temperature >= 30;
  bool get isCold => temperature <= 12;
  bool get isHumid => humidity >= 75;
  bool get isRainy => rainChance >= 60 || precipitation > 0;
  bool get isWindy => windSpeed >= 25;
}

class WeatherFarmProfile {
  final String id;
  final String profileName;
  final String cropEn;
  final String cropNe;
  final WeatherPlace place;
  final String updatedAt;

  WeatherFarmProfile({
    required this.id,
    required this.profileName,
    required this.cropEn,
    required this.cropNe,
    required this.place,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileName': profileName,
      'cropEn': cropEn,
      'cropNe': cropNe,
      'place': place.toJson(),
      'updatedAt': updatedAt,
    };
  }

  factory WeatherFarmProfile.fromJson(Map<String, dynamic> json) {
    return WeatherFarmProfile(
      id: (json['id'] ?? '').toString(),
      profileName: (json['profileName'] ?? '').toString(),
      cropEn: (json['cropEn'] ?? '').toString(),
      cropNe: (json['cropNe'] ?? '').toString(),
      place: WeatherPlace.fromJson(
        Map<String, dynamic>.from(json['place'] ?? {}),
      ),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}

class WeatherAdviceHistory {
  final String id;
  final String cropEn;
  final String cropNe;
  final String placeName;
  final String alertEn;
  final String alertNe;
  final String actionOneEn;
  final String actionOneNe;
  final String actionTwoEn;
  final String actionTwoNe;
  final String cropAdviceEn;
  final String cropAdviceNe;
  final String createdAt;

  WeatherAdviceHistory({
    required this.id,
    required this.cropEn,
    required this.cropNe,
    required this.placeName,
    required this.alertEn,
    required this.alertNe,
    required this.actionOneEn,
    required this.actionOneNe,
    required this.actionTwoEn,
    required this.actionTwoNe,
    required this.cropAdviceEn,
    required this.cropAdviceNe,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropEn': cropEn,
      'cropNe': cropNe,
      'placeName': placeName,
      'alertEn': alertEn,
      'alertNe': alertNe,
      'actionOneEn': actionOneEn,
      'actionOneNe': actionOneNe,
      'actionTwoEn': actionTwoEn,
      'actionTwoNe': actionTwoNe,
      'cropAdviceEn': cropAdviceEn,
      'cropAdviceNe': cropAdviceNe,
      'createdAt': createdAt,
    };
  }

  factory WeatherAdviceHistory.fromJson(Map<String, dynamic> json) {
    return WeatherAdviceHistory(
      id: (json['id'] ?? '').toString(),
      cropEn: (json['cropEn'] ?? '').toString(),
      cropNe: (json['cropNe'] ?? '').toString(),
      placeName: (json['placeName'] ?? '').toString(),
      alertEn: (json['alertEn'] ?? '').toString(),
      alertNe: (json['alertNe'] ?? '').toString(),
      actionOneEn: (json['actionOneEn'] ?? '').toString(),
      actionOneNe: (json['actionOneNe'] ?? '').toString(),
      actionTwoEn: (json['actionTwoEn'] ?? '').toString(),
      actionTwoNe: (json['actionTwoNe'] ?? '').toString(),
      cropAdviceEn: (json['cropAdviceEn'] ?? '').toString(),
      cropAdviceNe: (json['cropAdviceNe'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class WeatherService {
  static const String _savedPlacesKey = 'saved_weather_places';
  static const String _selectedPlaceKey = 'selected_weather_place';
  static const String _farmProfilesKey = 'weather_farm_profiles';
  static const String _selectedFarmProfileKey = 'selected_weather_farm_profile';
  static const String _weatherHistoryKey = 'weather_advice_history';

  static String? _currentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static String _userKey(String baseKey) {
    final uid = _currentUserId();

    if (uid == null || uid.trim().isEmpty) {
      return '${baseKey}_guest';
    }

    return '${baseKey}_$uid';
  }

  static Future<List<WeatherPlace>> searchPlaces(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return [];
    }

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': cleanQuery,
      'count': '10',
      'language': 'en',
      'format': 'json',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Location search failed. Please try again.');
    }

    final decoded = jsonDecode(response.body);
    final results = decoded['results'];

    if (results is! List) {
      return [];
    }

    return results.map((item) {
      return WeatherPlace.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  static Future<WeatherPlace> getCurrentLocationPlace() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location service is disabled. Please turn it on.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable it from settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    ).timeout(const Duration(seconds: 20));

    String name = 'Current Location';
    String admin1 = '';
    String country = '';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        name = (place.locality?.trim().isNotEmpty ?? false)
            ? place.locality!.trim()
            : ((place.subAdministrativeArea?.trim().isNotEmpty ?? false)
                  ? place.subAdministrativeArea!.trim()
                  : 'Current Location');

        admin1 = place.administrativeArea ?? '';
        country = place.country ?? '';
      }
    } catch (_) {
      name = 'Current Location';
    }

    return WeatherPlace(
      name: name,
      country: country,
      admin1: admin1,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static Future<WeatherResult> fetchWeather(WeatherPlace place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.latitude.toString(),
      'longitude': place.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,precipitation,rain,weather_code,wind_speed_10m',
      'hourly': 'precipitation_probability',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'forecast_days': '5',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Weather data failed. Please try again.');
    }

    final decoded = jsonDecode(response.body);
    final current = decoded['current'];

    if (current is! Map) {
      throw Exception('Weather response is invalid.');
    }

    int rainChance = 0;

    final hourly = decoded['hourly'];

    if (hourly is Map && hourly['precipitation_probability'] is List) {
      final list = hourly['precipitation_probability'] as List;

      if (list.isNotEmpty) {
        final firstSixHours = list.take(6).toList();

        final values = firstSixHours
            .map((item) => _toInt(item))
            .where((value) => value >= 0)
            .toList();

        if (values.isNotEmpty) {
          rainChance = values.reduce((a, b) => a > b ? a : b).clamp(0, 100);
        }
      }
    }

    final precipitation = _toDouble(current['precipitation']);
    final rain = _toDouble(current['rain']);

    if (rainChance == 0 && (precipitation > 0 || rain > 0)) {
      rainChance = 70;
    }

    final forecast = _buildDailyForecast(decoded['daily']);

    return WeatherResult(
      place: place,
      temperature: _toDouble(current['temperature_2m']),
      humidity: _toInt(current['relative_humidity_2m']).clamp(0, 100),
      windSpeed: _toDouble(current['wind_speed_10m']),
      weatherCode: _toInt(current['weather_code']),
      precipitation: precipitation + rain,
      rainChance: rainChance,
      forecast: forecast,
    );
  }

  static List<DailyWeather> _buildDailyForecast(dynamic daily) {
    if (daily is! Map) return <DailyWeather>[];

    final dates = daily['time'];
    final codes = daily['weather_code'];
    final maxTemps = daily['temperature_2m_max'];
    final minTemps = daily['temperature_2m_min'];
    final rainChances = daily['precipitation_probability_max'];

    if (dates is! List ||
        codes is! List ||
        maxTemps is! List ||
        minTemps is! List ||
        rainChances is! List) {
      return <DailyWeather>[];
    }

    final lengths = <int>[
      dates.length,
      codes.length,
      maxTemps.length,
      minTemps.length,
      rainChances.length,
    ];

    final count = lengths.reduce((a, b) => a < b ? a : b);
    final forecast = <DailyWeather>[];

    for (int i = 0; i < count; i++) {
      forecast.add(
        DailyWeather(
          date: dates[i].toString(),
          maxTemp: _toDouble(maxTemps[i]),
          minTemp: _toDouble(minTemps[i]),
          rainChance: _toInt(rainChances[i]).clamp(0, 100),
          weatherCode: _toInt(codes[i]),
        ),
      );
    }

    return forecast;
  }

  static Future<void> savePlace(WeatherPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPlaces = await getSavedPlaces();

    final alreadyExists = currentPlaces.any((item) {
      return item.name == place.name &&
          item.country == place.country &&
          item.latitude == place.latitude &&
          item.longitude == place.longitude;
    });

    if (!alreadyExists) {
      currentPlaces.add(place);
    }

    final encoded = currentPlaces.map((item) => item.toJson()).toList();

    await prefs.setString(_userKey(_savedPlacesKey), jsonEncode(encoded));
    await prefs.setString(
      _userKey(_selectedPlaceKey),
      jsonEncode(place.toJson()),
    );
  }

  static Future<void> selectPlace(WeatherPlace place) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey(_selectedPlaceKey),
      jsonEncode(place.toJson()),
    );
  }

  static Future<WeatherPlace?> getSelectedPlace() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userKey(_selectedPlaceKey));

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      return WeatherPlace.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<List<WeatherPlace>> getSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userKey(_savedPlacesKey));

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded.map((item) {
        return WeatherPlace.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> removeSavedPlace(WeatherPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPlaces = await getSavedPlaces();

    currentPlaces.removeWhere((item) {
      return item.name == place.name &&
          item.country == place.country &&
          item.latitude == place.latitude &&
          item.longitude == place.longitude;
    });

    final encoded = currentPlaces.map((item) => item.toJson()).toList();

    await prefs.setString(_userKey(_savedPlacesKey), jsonEncode(encoded));

    final selected = await getSelectedPlace();

    if (selected != null &&
        selected.name == place.name &&
        selected.country == place.country &&
        selected.latitude == place.latitude &&
        selected.longitude == place.longitude) {
      await prefs.remove(_userKey(_selectedPlaceKey));
    }
  }

  static Future<void> saveFarmProfile(WeatherFarmProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getFarmProfiles();

    profiles.removeWhere((item) => item.id == profile.id);
    profiles.insert(0, profile);

    final encoded = profiles.map((item) => item.toJson()).toList();

    await prefs.setString(_userKey(_farmProfilesKey), jsonEncode(encoded));
    await prefs.setString(
      _userKey(_selectedFarmProfileKey),
      jsonEncode(profile.toJson()),
    );
  }

  static Future<List<WeatherFarmProfile>> getFarmProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userKey(_farmProfilesKey));

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded.map((item) {
        return WeatherFarmProfile.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> selectFarmProfile(WeatherFarmProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _userKey(_selectedFarmProfileKey),
      jsonEncode(profile.toJson()),
    );

    await selectPlace(profile.place);
  }

  static Future<WeatherFarmProfile?> getSelectedFarmProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userKey(_selectedFarmProfileKey));

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      return WeatherFarmProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeFarmProfile(WeatherFarmProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getFarmProfiles();

    profiles.removeWhere((item) => item.id == profile.id);

    final encoded = profiles.map((item) => item.toJson()).toList();

    await prefs.setString(_userKey(_farmProfilesKey), jsonEncode(encoded));

    final selected = await getSelectedFarmProfile();

    if (selected != null && selected.id == profile.id) {
      await prefs.remove(_userKey(_selectedFarmProfileKey));
    }
  }

  static Future<void> saveAdviceHistory(WeatherAdviceHistory history) async {
    final prefs = await SharedPreferences.getInstance();
    final histories = await getAdviceHistory();

    histories.insert(0, history);

    final limited = histories.take(20).toList();
    final encoded = limited.map((item) => item.toJson()).toList();

    await prefs.setString(_userKey(_weatherHistoryKey), jsonEncode(encoded));
  }

  static Future<List<WeatherAdviceHistory>> getAdviceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_userKey(_weatherHistoryKey));

    if (value == null || value.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return [];
      }

      return decoded.map((item) {
        return WeatherAdviceHistory.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearAdviceHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userKey(_weatherHistoryKey));
  }

  static Future<void> clearAllCurrentUserWeatherData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userKey(_savedPlacesKey));
    await prefs.remove(_userKey(_selectedPlaceKey));
    await prefs.remove(_userKey(_farmProfilesKey));
    await prefs.remove(_userKey(_selectedFarmProfileKey));
    await prefs.remove(_userKey(_weatherHistoryKey));
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }
}
