import 'dart:io';

class RealAiScanService {
  static Future<Map<String, dynamic>> scanPlantImage({
    required File imageFile,
    required String farmerNote,
  }) async {
    /*
      FUTURE REAL AI FLOW:

      1. Upload image to secure backend or Firebase Storage
      2. Backend sends image to AI vision model
      3. AI detects:
         - plant/crop name
         - affected part
         - disease/pest/problem
         - confidence
         - treatment
         - prevention
      4. Backend returns result
      5. App saves result to Firestore

      IMPORTANT:
      Do not put real AI API keys directly inside Flutter app.
      We will use backend/cloud function later.
    */

    await Future.delayed(const Duration(milliseconds: 500));

    return {
      'realAiScanStatus': 'not_started',
      'realAiScanMessage': 'Real image AI scan is not connected yet.',
    };
  }
}