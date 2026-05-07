import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiCropAiService {
  static const String _apiKey = 'AIzaSyCAAoVjupDz5lxfYSxqKGk9ahWMWj-DvO8';

  static Future<Map<String, dynamic>> scanPlantWithGemini({
    required File imageFile,
    required String farmerNote,
  }) async {
    if (_apiKey.trim().isEmpty ||
        _apiKey == 'AIzaSyCAAoVjupDz5lxfYSxqKGk9ahWMWj-DvO8') {
      return {
        'backendAiStatus': 'failed',
        'backendAiMessage': 'Gemini API key is not added yet.',
        'backendAiMessageNe': 'Gemini API key अझै थपिएको छैन।',
        'aiStatus': 'not_processed',
      };
    }

    try {
      final imageBytes = await imageFile.readAsBytes();

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      final prompt =
          '''
You are an agriculture crop disease assistant for Nepali farmers.

Analyze this plant/crop image and farmer note.

Farmer note:
$farmerNote

Return only simple JSON. Do not use markdown.

Use this exact JSON structure:
{
  "aiStatus": "processed",
  "aiPlantName": "",
  "aiPlantNameNe": "",
  "aiAffectedPart": "",
  "aiAffectedPartNe": "",
  "aiProblemName": "",
  "aiProblemNameNe": "",
  "aiProblemType": "",
  "aiProblemTypeNe": "",
  "aiConfidence": 0,
  "aiSeverity": "",
  "aiSeverityNe": "",
  "aiUrgency": "",
  "aiUrgencyNe": "",
  "aiImageQuality": "",
  "aiImageQualityNe": "",
  "aiWhatHappened": "",
  "aiWhatHappenedNe": "",
  "aiWhyItHappened": "",
  "aiWhyItHappenedNe": "",
  "aiTreatmentSteps": [],
  "aiTreatmentStepsNe": [],
  "aiPreventionTips": [],
  "aiPreventionTipsNe": [],
  "aiWhenToAskExpert": "",
  "aiWhenToAskExpertNe": ""
}

Rules:
- Give farmer-friendly simple language.
- If image is not clear, say upload clearer photo.
- Do not recommend dangerous chemical dosage.
- Tell farmer to ask local agriculture expert before chemical use.
- Use English and Nepali.
''';

      final response = await model
          .generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ]),
          ])
          .timeout(const Duration(seconds: 40));

      final text = response.text ?? '';

      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');

      if (jsonStart == -1 || jsonEnd == -1) {
        return _failedResult('Gemini did not return valid JSON.');
      }

      final jsonText = cleaned.substring(jsonStart, jsonEnd + 1);

      final decoded = _safeDecode(jsonText);

      if (decoded == null) {
        return _failedResult('Gemini response could not be parsed.');
      }

      return {
        'backendAiStatus': 'completed',
        'backendAiMessage': 'Gemini AI checked the plant photo successfully.',
        'backendAiMessageNe':
            'Gemini AI ले बिरुवाको फोटो सफलतापूर्वक जाँच गर्‍यो।',

        'aiStatus': decoded['aiStatus'] ?? 'processed',

        'aiPlantName': decoded['aiPlantName'] ?? '',
        'aiPlantNameNe': decoded['aiPlantNameNe'] ?? '',

        'aiAffectedPart': decoded['aiAffectedPart'] ?? '',
        'aiAffectedPartNe': decoded['aiAffectedPartNe'] ?? '',

        'aiProblemName': decoded['aiProblemName'] ?? '',
        'aiProblemNameNe': decoded['aiProblemNameNe'] ?? '',

        'aiProblemType': decoded['aiProblemType'] ?? '',
        'aiProblemTypeNe': decoded['aiProblemTypeNe'] ?? '',

        'aiConfidence': decoded['aiConfidence'] ?? 0,

        'aiSeverity': decoded['aiSeverity'] ?? 'Unknown',
        'aiSeverityNe': decoded['aiSeverityNe'] ?? 'थाहा छैन',

        'aiUrgency': decoded['aiUrgency'] ?? 'Normal',
        'aiUrgencyNe': decoded['aiUrgencyNe'] ?? 'सामान्य',

        'aiImageQuality': decoded['aiImageQuality'] ?? 'Unknown',
        'aiImageQualityNe': decoded['aiImageQualityNe'] ?? 'थाहा छैन',

        'aiWhatHappened': decoded['aiWhatHappened'] ?? '',
        'aiWhatHappenedNe': decoded['aiWhatHappenedNe'] ?? '',

        'aiWhyItHappened': decoded['aiWhyItHappened'] ?? '',
        'aiWhyItHappenedNe': decoded['aiWhyItHappenedNe'] ?? '',

        'aiTreatmentSteps': _toStringList(decoded['aiTreatmentSteps']),
        'aiTreatmentStepsNe': _toStringList(decoded['aiTreatmentStepsNe']),

        'aiPreventionTips': _toStringList(decoded['aiPreventionTips']),
        'aiPreventionTipsNe': _toStringList(decoded['aiPreventionTipsNe']),

        'aiWhenToAskExpert': decoded['aiWhenToAskExpert'] ?? '',
        'aiWhenToAskExpertNe': decoded['aiWhenToAskExpertNe'] ?? '',
      };
    } catch (e) {
      return _failedResult('Gemini AI failed: $e');
    }
  }

  static Map<String, dynamic>? _safeDecode(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
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

  static Map<String, dynamic> _failedResult(String message) {
    return {
      'backendAiStatus': 'failed',
      'backendAiMessage': message,
      'backendAiMessageNe': 'Gemini AI जाँच असफल भयो।',
      'aiStatus': 'not_processed',
    };
  }
}
