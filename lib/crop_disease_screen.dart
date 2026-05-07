import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'gemini_crop_ai_service.dart';
import 'ai_diagnosis_service.dart';
import 'app_language.dart';
import 'image_upload_service.dart';

class CropDiseaseScreen extends StatefulWidget {
  const CropDiseaseScreen({super.key});

  @override
  State<CropDiseaseScreen> createState() => _CropDiseaseScreenState();
}

class _CropDiseaseScreenState extends State<CropDiseaseScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isSubmitting = false;

  final List<String> _selectedSymptoms = [];

  final List<Map<String, String>> _symptoms = [
    {'en': 'Yellow leaves', 'ne': 'पात पहेँलो'},
    {'en': 'Brown spots', 'ne': 'खैरो दाग'},
    {'en': 'White powder', 'ne': 'सेतो धुलो'},
    {'en': 'Insects or holes', 'ne': 'किरा वा प्वाल'},
    {'en': 'Drying or wilting', 'ne': 'सुक्ने वा ओइलाउने'},
  ];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  String _combinedFarmerNote() {
    final typedNote = _noteController.text.trim();
    final symptomsText = _selectedSymptoms.join(', ');

    if (typedNote.isEmpty && symptomsText.isEmpty) {
      return '';
    }

    if (typedNote.isEmpty) {
      return symptomsText;
    }

    if (symptomsText.isEmpty) {
      return typedNote;
    }

    return '$typedNote. Symptoms: $symptomsText';
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<String>(
              valueListenable: AppLanguage.language,
              builder: (context, language, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLanguage.text(
                        'Select Photo Option',
                        'फोटो विकल्प छान्नुहोस्',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.camera_alt, color: Colors.green),
                      ),
                      title: Text(
                        AppLanguage.text('Take Photo', 'फोटो खिच्नुहोस्'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        AppLanguage.text(
                          'Use camera to capture plant problem',
                          'क्यामेराबाट बिरुवाको समस्या खिच्नुहोस्',
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.photo_library, color: Colors.green),
                      ),
                      title: Text(
                        AppLanguage.text(
                          'Choose From Gallery',
                          'ग्यालरीबाट छान्नुहोस्',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        AppLanguage.text(
                          'Select existing plant photo',
                          'पहिलेको बिरुवाको फोटो छान्नुहोस्',
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (_selectedImage == null) {
      _showMessage(
        AppLanguage.text(
          'Please select a plant photo first',
          'कृपया पहिले बिरुवाको फोटो छान्नुहोस्',
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        AppLanguage.text('You must be logged in', 'तपाईं लगइन भएको हुनुपर्छ'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final farmerNote = _combinedFarmerNote();

      final basicAiResult = AiDiagnosisService.diagnoseFromNote(farmerNote);

      final imageUploadResult = await ImageUploadService.uploadPlantImage(
        imageFile: _selectedImage!,
        userId: user.uid,
      );

      final backendAiResult = await GeminiCropAiService.scanPlantWithGemini(
        imageFile: _selectedImage!,
        farmerNote: farmerNote,
      );

      final bool useBackendResult =
          backendAiResult['backendAiStatus'] == 'completed';

      final Map<String, dynamic> finalAiResult = useBackendResult
          ? backendAiResult
          : basicAiResult;

      final backendImageUrl =
          backendAiResult['imageUrl']?.toString().trim() ?? '';

      final savedImageUrl = backendImageUrl.isNotEmpty
          ? backendImageUrl
          : imageUploadResult['imageUrl'];

      final savedImageUploadStatus = backendImageUrl.isNotEmpty
          ? 'uploaded'
          : imageUploadResult['imageUploadStatus'];

      await FirebaseFirestore.instance.collection('cropReports').add({
        'userId': user.uid,
        'userEmail': user.email,

        'farmerNote': farmerNote,
        'selectedSymptoms': _selectedSymptoms,

        'hasLocalImageSelected': true,
        'imageUploadStatus': savedImageUploadStatus,
        'imageUrl': savedImageUrl,

        'status': 'pending_review',
        'adminComment': '',

        'backendAiStatus':
            backendAiResult['backendAiStatus'] ?? 'not_connected',
        'backendAiMessage': backendAiResult['backendAiMessage'] ?? '',
        'backendAiMessageNe': backendAiResult['backendAiMessageNe'] ?? '',

        'aiStatus': finalAiResult['aiStatus'] ?? 'not_processed',

        'aiPlantName': finalAiResult['aiPlantName'] ?? '',
        'aiPlantNameNe': finalAiResult['aiPlantNameNe'] ?? '',

        'aiAffectedPart': finalAiResult['aiAffectedPart'] ?? '',
        'aiAffectedPartNe': finalAiResult['aiAffectedPartNe'] ?? '',

        'aiProblemName': finalAiResult['aiProblemName'] ?? '',
        'aiProblemNameNe': finalAiResult['aiProblemNameNe'] ?? '',

        'aiProblemType': finalAiResult['aiProblemType'] ?? '',
        'aiProblemTypeNe': finalAiResult['aiProblemTypeNe'] ?? '',

        'aiConfidence': finalAiResult['aiConfidence'] ?? 0,

        'aiSeverity': finalAiResult['aiSeverity'] ?? 'Unknown',
        'aiSeverityNe': finalAiResult['aiSeverityNe'] ?? 'थाहा छैन',

        'aiUrgency': finalAiResult['aiUrgency'] ?? 'Normal',
        'aiUrgencyNe': finalAiResult['aiUrgencyNe'] ?? 'सामान्य',

        'aiImageQuality': finalAiResult['aiImageQuality'] ?? 'Unknown',
        'aiImageQualityNe': finalAiResult['aiImageQualityNe'] ?? 'थाहा छैन',

        'aiWhatHappened': finalAiResult['aiWhatHappened'] ?? '',
        'aiWhatHappenedNe': finalAiResult['aiWhatHappenedNe'] ?? '',

        'aiWhyItHappened': finalAiResult['aiWhyItHappened'] ?? '',
        'aiWhyItHappenedNe': finalAiResult['aiWhyItHappenedNe'] ?? '',

        'aiTreatmentSteps': finalAiResult['aiTreatmentSteps'] ?? [],
        'aiTreatmentStepsNe': finalAiResult['aiTreatmentStepsNe'] ?? [],

        'aiPreventionTips': finalAiResult['aiPreventionTips'] ?? [],
        'aiPreventionTipsNe': finalAiResult['aiPreventionTipsNe'] ?? [],

        'aiWhenToAskExpert': finalAiResult['aiWhenToAskExpert'] ?? '',
        'aiWhenToAskExpertNe': finalAiResult['aiWhenToAskExpertNe'] ?? '',

        'expertVerified': false,
        'aiSource': useBackendResult ? 'backend' : 'basic_fallback',

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _noteController.clear();

      setState(() {
        _selectedImage = null;
        _selectedSymptoms.clear();
      });

      _showMessage(
        useBackendResult
            ? AppLanguage.text(
                'Plant report saved ✅ Backend AI result added.',
                'बिरुवाको रिपोर्ट सेभ भयो ✅ ब्याकएन्ड एआई नतिजा थपियो।',
              )
            : AppLanguage.text(
                'Plant report saved ✅ Basic AI guidance added.',
                'बिरुवाको रिपोर्ट सेभ भयो ✅ आधारभूत एआई सुझाव थपियो।',
              ),
      );
    } catch (e) {
      _showMessage(
        AppLanguage.text(
          'Failed to save report: $e',
          'रिपोर्ट सेभ गर्न समस्या भयो: $e',
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Plant Problem Check', 'बिरुवा समस्या जाँच'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(),
                const SizedBox(height: 18),
                _mainCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.camera_alt, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(
                    'Take a Plant Photo',
                    'बिरुवाको फोटो छान्नुहोस्',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLanguage.text(
                    'Take or select a clear plant photo. Tap symptoms if you cannot type.',
                    'सफा बिरुवाको फोटो खिच्नुहोस् वा छान्नुहोस्। लेख्न गाह्रो भए लक्षण थिच्नुहोस्।',
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _imagePickerBox(),
          const SizedBox(height: 16),
          _symptomSelector(),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppLanguage.text('Optional note', 'वैकल्पिक नोट'),
              hintText: AppLanguage.text(
                'Example: Leaves are yellow or plant is drying',
                'उदाहरण: पात पहेँलो छ वा बिरुवा सुक्दैछ',
              ),
              prefixIcon: Icon(Icons.edit_note, color: Colors.green.shade700),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLanguage.text(
                      'Tip: For best result, upload a clear close photo of the affected leaf, fruit, stem or whole plant.',
                      'सुझाव: राम्रो नतिजाका लागि समस्या भएको पात, फल, डाँठ वा पूरा बिरुवाको नजिकबाट खिचिएको सफा फोटो राख्नुहोस्।',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReport,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.psychology_alt),
              label: Text(
                _isSubmitting
                    ? AppLanguage.text('Saving...', 'सेभ हुँदैछ...')
                    : AppLanguage.text(
                        'Check Plant Problem',
                        'बिरुवा समस्या जाँच गर्नुहोस्',
                      ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _symptomSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.touch_app, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLanguage.text(
                    'Tap symptoms you see',
                    'देखिएको लक्षण थिच्नुहोस्',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _symptoms.map((symptom) {
              final english = symptom['en']!;
              final nepali = symptom['ne']!;
              final selected = _selectedSymptoms.contains(english);

              return FilterChip(
                label: Text(AppLanguage.text(english, nepali)),
                selected: selected,
                selectedColor: Colors.green.shade200,
                checkmarkColor: Colors.green.shade900,
                onSelected: (_) => _toggleSymptom(english),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _imagePickerBox() {
    return GestureDetector(
      onTap: _showImageSourceOptions,
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green.shade300),
          borderRadius: BorderRadius.circular(18),
          color: Colors.green.shade50,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 58,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLanguage.text(
                      'Tap to add plant photo',
                      'बिरुवाको फोटो थप्न यहाँ थिच्नुहोस्',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppLanguage.text(
                      'Take photo or choose from gallery',
                      'फोटो खिच्नुहोस् वा ग्यालरीबाट छान्नुहोस्',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLanguage.text(
                      'Leaf, fruit, stem, root or whole plant',
                      'पात, फल, डाँठ, जरा वा पूरा बिरुवा',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppLanguage.text(
                          'Tap to change photo',
                          'फोटो बदल्न थिच्नुहोस्',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
