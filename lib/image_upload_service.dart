import 'dart:io';

class ImageUploadService {
  static Future<Map<String, String>> uploadPlantImage({
    required File imageFile,
    required String userId,
  }) async {
    /*
      FUTURE REAL UPLOAD FLOW:

      Later this service will upload the selected plant image to:
      1. Firebase Storage, or
      2. Your secure backend server.

      Then it will return:
      imageUploadStatus: uploaded
      imageUrl: uploaded image URL

      For now Firebase Storage/backend is not connected,
      so we keep safe temporary values.
    */

    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'imageUploadStatus': 'not_uploaded_yet',
      'imageUrl': '',
    };
  }
}