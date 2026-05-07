import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'weather_service.dart';

class WeatherAiResult {
  final bool success;
  final String weatherAiStatus;
  final String weatherAiMessage;
  final String weatherAiMessageNe;

  final String aiWeatherTitle;
  final String aiWeatherTitleNe;
  final String aiWeatherSummary;
  final String aiWeatherSummaryNe;
  final String aiWeatherRisk;
  final String aiWeatherRiskNe;
  final List<String> aiWeatherActions;
  final List<String> aiWeatherActionsNe;

  WeatherAiResult({
    required this.success,
    required this.weatherAiStatus,
    required this.weatherAiMessage,
    required this.weatherAiMessageNe,
    required this.aiWeatherTitle,
    required this.aiWeatherTitleNe,
    required this.aiWeatherSummary,
    required this.aiWeatherSummaryNe,
    required this.aiWeatherRisk,
    required this.aiWeatherRiskNe,
    required this.aiWeatherActions,
    required this.aiWeatherActionsNe,
  });

  factory WeatherAiResult.fromJson(Map<String, dynamic> json) {
    return WeatherAiResult(
      success: json['success'] == true,
      weatherAiStatus: (json['weatherAiStatus'] ?? 'failed').toString(),
      weatherAiMessage: (json['weatherAiMessage'] ?? '').toString(),
      weatherAiMessageNe: (json['weatherAiMessageNe'] ?? '').toString(),
      aiWeatherTitle: (json['aiWeatherTitle'] ?? 'AI Weather Advice')
          .toString(),
      aiWeatherTitleNe: (json['aiWeatherTitleNe'] ?? 'एआई मौसम सुझाव')
          .toString(),
      aiWeatherSummary: (json['aiWeatherSummary'] ?? '').toString(),
      aiWeatherSummaryNe: (json['aiWeatherSummaryNe'] ?? '').toString(),
      aiWeatherRisk: (json['aiWeatherRisk'] ?? 'Normal').toString(),
      aiWeatherRiskNe: (json['aiWeatherRiskNe'] ?? 'सामान्य').toString(),
      aiWeatherActions: _toStringList(json['aiWeatherActions']),
      aiWeatherActionsNe: _toStringList(json['aiWeatherActionsNe']),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return [];
  }
}

class WeatherAiService {
  static Future<WeatherAiResult> getWeatherAiSummary({
    required String cropName,
    required String cropNameNe,
    required WeatherResult weather,
    required String mainAlert,
    required String localAdvice,
  }) async {
    if (!BackendConfig.isBackendConnected) {
      return _localWeatherAdvice(
        cropName: cropName,
        cropNameNe: cropNameNe,
        weather: weather,
        mainAlert: mainAlert,
        localAdvice: localAdvice,
      );
    }

    final forecastText = weather.forecast
        .map((day) {
          return '${day.dayLabel}: ${day.weatherType}, high ${day.maxTempText}, low ${day.minTempText}, rain ${day.rainChanceText}';
        })
        .join(' | ');

    final uri = Uri.parse(BackendConfig.weatherAiSummaryEndpoint);

    final body = {
      'cropName': cropName,
      'cropNameNe': cropNameNe,
      'placeName': weather.place.displayName,
      'temperature': weather.temperatureText,
      'humidity': weather.humidityText,
      'rainChance': weather.rainChanceText,
      'windSpeed': weather.windText,
      'weatherType': weather.weatherType,
      'mainAlert': mainAlert,
      'localAdvice': localAdvice,
      'forecastText': forecastText,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid AI weather response.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(decoded['weatherAiMessage'] ?? 'AI weather failed.');
      }

      return WeatherAiResult.fromJson(decoded);
    } catch (_) {
      return _localWeatherAdvice(
        cropName: cropName,
        cropNameNe: cropNameNe,
        weather: weather,
        mainAlert: mainAlert,
        localAdvice: localAdvice,
      );
    }
  }

  static WeatherAiResult _localWeatherAdvice({
    required String cropName,
    required String cropNameNe,
    required WeatherResult weather,
    required String mainAlert,
    required String localAdvice,
  }) {
    final cleanCropName = cropName.trim().isEmpty ? 'Crop' : cropName.trim();
    final cleanCropNameNe = cropNameNe.trim().isEmpty
        ? 'बाली'
        : cropNameNe.trim();

    String riskEn = 'Normal';
    String riskNe = 'सामान्य';
    String titleEn = '$cleanCropName weather advice';
    String titleNe = '$cleanCropNameNe मौसम सुझाव';

    final actionsEn = <String>[];
    final actionsNe = <String>[];

    if (weather.isRainy) {
      riskEn = 'Rain risk';
      riskNe = 'पानी पर्ने जोखिम';

      actionsEn.add(
        'Avoid spraying today because rain can wash medicine away.',
      );
      actionsEn.add('Check drainage so water does not stay around roots.');
      actionsEn.add('Protect young plants from heavy rain.');

      actionsNe.add('आज छर्कने काम नगर्नुहोस् किनकि पानीले औषधि बगाउन सक्छ।');
      actionsNe.add('जराको वरिपरि पानी नजम्ने गरी निकास जाँच गर्नुहोस्।');
      actionsNe.add('धेरै पानीबाट साना बिरुवा जोगाउनुहोस्।');
    } else if (weather.isHot) {
      riskEn = 'Heat risk';
      riskNe = 'गर्मी जोखिम';

      actionsEn.add('Water early morning or late afternoon.');
      actionsEn.add('Check soil moisture before adding more water.');
      actionsEn.add('Use mulch if possible to reduce moisture loss.');

      actionsNe.add('बिहान सबेरै वा साँझ पानी दिनुहोस्।');
      actionsNe.add('थप पानी दिनु अघि माटोको चिस्यान जाँच गर्नुहोस्।');
      actionsNe.add('सम्भव भए माटोको चिस्यान जोगाउन मल्च प्रयोग गर्नुहोस्।');
    } else if (weather.isCold) {
      riskEn = 'Cold risk';
      riskNe = 'चिसो जोखिम';

      actionsEn.add('Protect seedlings and sensitive crops from cold.');
      actionsEn.add('Avoid overwatering in cold weather.');
      actionsEn.add('Check plants in the morning for cold stress.');

      actionsNe.add('साना बिरुवा र संवेदनशील बालीलाई चिसोबाट जोगाउनुहोस्।');
      actionsNe.add('चिसो मौसममा धेरै पानी नदिनुहोस्।');
      actionsNe.add('बिहान बिरुवामा चिसोको असर छ कि छैन जाँच गर्नुहोस्।');
    } else if (weather.isWindy) {
      riskEn = 'Wind risk';
      riskNe = 'हावाको जोखिम';

      actionsEn.add('Avoid spraying because wind can blow chemicals away.');
      actionsEn.add('Support weak plants if needed.');
      actionsEn.add('Check for broken stems or damaged leaves.');

      actionsNe.add('हावाले औषधि उडाउन सक्ने भएकाले छर्कने काम नगर्नुहोस्।');
      actionsNe.add('कमजोर बिरुवालाई आवश्यक भए support दिनुहोस्।');
      actionsNe.add('भाँचिएको डाँठ वा बिग्रिएको पात जाँच गर्नुहोस्।');
    } else if (weather.isHumid) {
      riskEn = 'Disease risk';
      riskNe = 'रोगको जोखिम';

      actionsEn.add(
        'Check leaves for fungal signs such as spots or white powder.',
      );
      actionsEn.add('Keep good spacing and airflow between plants.');
      actionsEn.add('Remove badly affected leaves if safe to do so.');

      actionsNe.add('पातमा दाग वा सेतो धुलो जस्ता फंगल लक्षण जाँच गर्नुहोस्।');
      actionsNe.add('बिरुवाबीच दूरी र हावा चल्ने अवस्था राम्रो राख्नुहोस्।');
      actionsNe.add('धेरै बिग्रिएको पात सुरक्षित भए हटाउनुहोस्।');
    } else {
      actionsEn.add('Continue normal crop care.');
      actionsEn.add('Monitor leaves, soil moisture and pests regularly.');
      actionsEn.add('Check weather again before spraying or watering.');

      actionsNe.add('सामान्य बाली हेरचाह जारी राख्नुहोस्।');
      actionsNe.add('पात, माटोको चिस्यान र किरा नियमित जाँच गर्नुहोस्।');
      actionsNe.add('छर्कने वा पानी दिने अघि फेरि मौसम जाँच गर्नुहोस्।');
    }

    return WeatherAiResult(
      success: true,
      weatherAiStatus: 'local_fallback',
      weatherAiMessage:
          'Backend AI is not connected. Local weather advice was created.',
      weatherAiMessageNe:
          'ब्याकएन्ड एआई जोडिएको छैन। स्थानीय मौसम सुझाव बनाइयो।',
      aiWeatherTitle: titleEn,
      aiWeatherTitleNe: titleNe,
      aiWeatherRisk: riskEn,
      aiWeatherRiskNe: riskNe,
      aiWeatherSummary:
          '$cleanCropName in ${weather.place.displayName}: ${weather.weatherType}, temperature ${weather.temperatureText}, humidity ${weather.humidityText}, rain chance ${weather.rainChanceText}. $mainAlert $localAdvice',
      aiWeatherSummaryNe:
          '$cleanCropNameNe का लागि ${weather.place.displayName} मा ${weather.weatherTypeNe}, तापक्रम ${weather.temperatureText}, आर्द्रता ${weather.humidityText}, पानीको सम्भावना ${weather.rainChanceText} छ। $localAdvice',
      aiWeatherActions: actionsEn,
      aiWeatherActionsNe: actionsNe,
    );
  }
}
