import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

class AiBackendService {
  static Future<Map<String, dynamic>> scanPlantWithBackend({
    required File imageFile,
    required String farmerNote,
    required String userId,
  }) async {
    if (!BackendConfig.isBackendConnected) {
      return _notConnectedResult();
    }

    final endpoint = BackendConfig.scanPlantEndpoint.trim();

    if (endpoint.isEmpty) {
      return _notConnectedResult();
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      request.fields['farmerNote'] = farmerNote;
      request.fields['userId'] = userId;

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 35),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        return {
          ..._basicFailedResult(),
          'backendAiMessage':
              'Backend request failed. Status: ${streamedResponse.statusCode}. $responseBody',
          'backendAiMessageNe':
              'ब्याकएन्ड अनुरोध असफल भयो। Status: ${streamedResponse.statusCode}',
        };
      }

      final decoded = jsonDecode(responseBody);

      if (decoded is! Map<String, dynamic>) {
        return {
          ..._basicFailedResult(),
          'backendAiMessage': 'Backend returned invalid response.',
          'backendAiMessageNe': 'ब्याकएन्डले गलत response पठायो।',
        };
      }

      return _normalizeBackendResult(decoded);
    } catch (e) {
      return {
        ..._basicFailedResult(),
        'backendAiMessage': 'Could not connect to backend: $e',
        'backendAiMessageNe': 'ब्याकएन्डसँग जडान हुन सकेन।',
      };
    }
  }

  static Map<String, dynamic> _notConnectedResult() {
    return {
      'backendAiStatus': 'not_connected',
      'backendAiMessage': 'Backend AI is not connected yet.',
      'backendAiMessageNe': 'ब्याकएन्ड एआई अझै जोडिएको छैन।',
    };
  }

  static Map<String, dynamic> _basicFailedResult() {
    return {
      'backendAiStatus': 'failed',
      'backendAiMessage': 'Backend AI failed.',
      'backendAiMessageNe': 'ब्याकएन्ड एआई असफल भयो।',

      'aiStatus': 'failed',
      'aiPlantName': '',
      'aiPlantNameNe': '',
      'aiAffectedPart': '',
      'aiAffectedPartNe': '',
      'aiProblemName': '',
      'aiProblemNameNe': '',
      'aiProblemType': '',
      'aiProblemTypeNe': '',
      'aiConfidence': 0,

      'aiSeverity': 'Unknown',
      'aiSeverityNe': 'थाहा छैन',
      'aiUrgency': 'Normal',
      'aiUrgencyNe': 'सामान्य',
      'aiImageQuality': 'Unknown',
      'aiImageQualityNe': 'थाहा छैन',

      'aiWhatHappened': '',
      'aiWhatHappenedNe': '',
      'aiWhyItHappened': '',
      'aiWhyItHappenedNe': '',
      'aiTreatmentSteps': <String>[],
      'aiTreatmentStepsNe': <String>[],
      'aiPreventionTips': <String>[],
      'aiPreventionTipsNe': <String>[],
      'aiWhenToAskExpert': '',
      'aiWhenToAskExpertNe': '',
      'imageUrl': '',
    };
  }

  static Map<String, dynamic> _normalizeBackendResult(
    Map<String, dynamic> decoded,
  ) {
    return {
      'backendAiStatus': _readString(decoded, [
        'backendAiStatus',
        'status',
      ], fallback: 'completed'),
      'backendAiMessage': _readString(decoded, [
        'backendAiMessage',
        'message',
      ], fallback: 'Plant image checked successfully.'),
      'backendAiMessageNe': _readString(decoded, [
        'backendAiMessageNe',
        'messageNe',
      ], fallback: 'बिरुवाको फोटो सफलतापूर्वक जाँच भयो।'),

      'aiStatus': _readString(decoded, ['aiStatus'], fallback: 'processed'),

      'aiPlantName': _readString(decoded, [
        'aiPlantName',
        'plantName',
        'cropName',
      ]),
      'aiPlantNameNe': _readString(decoded, [
        'aiPlantNameNe',
        'plantNameNe',
        'cropNameNe',
      ]),

      'aiAffectedPart': _readString(decoded, [
        'aiAffectedPart',
        'affectedPart',
      ]),
      'aiAffectedPartNe': _readString(decoded, [
        'aiAffectedPartNe',
        'affectedPartNe',
      ]),

      'aiProblemName': _readString(decoded, [
        'aiProblemName',
        'problemName',
        'diseaseName',
      ]),
      'aiProblemNameNe': _readString(decoded, [
        'aiProblemNameNe',
        'problemNameNe',
        'diseaseNameNe',
      ]),

      'aiProblemType': _readString(decoded, ['aiProblemType', 'problemType']),
      'aiProblemTypeNe': _readString(decoded, [
        'aiProblemTypeNe',
        'problemTypeNe',
      ]),

      'aiConfidence': _readNumber(decoded, ['aiConfidence', 'confidence']),

      'aiSeverity': _readString(decoded, [
        'aiSeverity',
        'severity',
      ], fallback: 'Unknown'),
      'aiSeverityNe': _readString(decoded, [
        'aiSeverityNe',
        'severityNe',
      ], fallback: 'थाहा छैन'),

      'aiUrgency': _readString(decoded, [
        'aiUrgency',
        'urgency',
      ], fallback: 'Normal'),
      'aiUrgencyNe': _readString(decoded, [
        'aiUrgencyNe',
        'urgencyNe',
      ], fallback: 'सामान्य'),

      'aiImageQuality': _readString(decoded, [
        'aiImageQuality',
        'imageQuality',
      ], fallback: 'Unknown'),
      'aiImageQualityNe': _readString(decoded, [
        'aiImageQualityNe',
        'imageQualityNe',
      ], fallback: 'थाहा छैन'),

      'aiWhatHappened': _readString(decoded, [
        'aiWhatHappened',
        'whatHappened',
      ]),
      'aiWhatHappenedNe': _readString(decoded, [
        'aiWhatHappenedNe',
        'whatHappenedNe',
      ]),

      'aiWhyItHappened': _readString(decoded, [
        'aiWhyItHappened',
        'whyItHappened',
      ]),
      'aiWhyItHappenedNe': _readString(decoded, [
        'aiWhyItHappenedNe',
        'whyItHappenedNe',
      ]),

      'aiTreatmentSteps': _readStringList(decoded, [
        'aiTreatmentSteps',
        'treatmentSteps',
        'treatment',
      ]),
      'aiTreatmentStepsNe': _readStringList(decoded, [
        'aiTreatmentStepsNe',
        'treatmentStepsNe',
        'treatmentNe',
      ]),

      'aiPreventionTips': _readStringList(decoded, [
        'aiPreventionTips',
        'preventionTips',
        'prevention',
      ]),
      'aiPreventionTipsNe': _readStringList(decoded, [
        'aiPreventionTipsNe',
        'preventionTipsNe',
        'preventionNe',
      ]),

      'aiWhenToAskExpert': _readString(decoded, [
        'aiWhenToAskExpert',
        'whenToAskExpert',
      ]),
      'aiWhenToAskExpertNe': _readString(decoded, [
        'aiWhenToAskExpertNe',
        'whenToAskExpertNe',
      ]),

      'imageUrl': _readString(decoded, [
        'imageUrl',
        'uploadedImageUrl',
        'photoUrl',
      ]),
    };
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value == null) continue;

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static num _readNumber(
    Map<String, dynamic> data,
    List<String> keys, {
    num fallback = 0,
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value is num) {
        return value;
      }

      if (value is String) {
        final number = num.tryParse(value.trim());
        if (number != null) return number;
      }
    }

    return fallback;
  }

  static List<String> _readStringList(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        return value
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    return <String>[];
  }
}
