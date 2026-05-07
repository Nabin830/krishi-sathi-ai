import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';

class AdminReportDetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AdminReportDetailScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  Future<void> _createFarmerNotification({
    required Map<String, dynamic> reportData,
    required Map<String, dynamic> reviewResult,
    required String reportId,
  }) async {
    final farmerUserId = (reportData['userId'] ?? '').toString().trim();

    if (farmerUserId.isEmpty) {
      return;
    }

    final plantName = (reviewResult['plantName'] ?? '').toString().trim();
    final plantNameNe = (reviewResult['plantNameNe'] ?? '').toString().trim();
    final problemName = (reviewResult['problemName'] ?? '').toString().trim();
    final problemNameNe = (reviewResult['problemNameNe'] ?? '')
        .toString()
        .trim();

    final cropText = plantName.isEmpty ? 'your crop report' : plantName;
    final cropTextNe = plantNameNe.isEmpty
        ? 'तपाईंको बाली रिपोर्ट'
        : plantNameNe;

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': farmerUserId,
      'type': 'crop_report_reviewed',
      'title': 'Your crop report has been reviewed',
      'titleNe': 'तपाईंको बाली रिपोर्ट समीक्षा भयो',
      'body': problemName.isEmpty
          ? 'Expert review is now available for $cropText. Open My Reports to check the advice.'
          : 'Expert review found: $problemName. Open My Reports to check treatment advice.',
      'bodyNe': problemNameNe.isEmpty
          ? '$cropTextNe को विशेषज्ञ समीक्षा उपलब्ध छ। सुझाव हेर्न My Reports खोल्नुहोस्।'
          : 'विशेषज्ञ समीक्षाले देखायो: $problemNameNe। उपचार सुझाव हेर्न My Reports खोल्नुहोस्।',
      'reportId': reportId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _reviewReport(
    BuildContext context,
    String docId,
    Map<String, dynamic> currentData,
  ) async {
    final TextEditingController commentController = TextEditingController(
      text: (currentData['adminComment'] ?? '').toString(),
    );

    final TextEditingController plantNameController = TextEditingController(
      text: (currentData['aiPlantName'] ?? '').toString(),
    );

    final TextEditingController plantNameNeController = TextEditingController(
      text: (currentData['aiPlantNameNe'] ?? '').toString(),
    );

    final TextEditingController affectedPartController = TextEditingController(
      text: (currentData['aiAffectedPart'] ?? '').toString(),
    );

    final TextEditingController affectedPartNeController =
        TextEditingController(
          text: (currentData['aiAffectedPartNe'] ?? '').toString(),
        );

    final TextEditingController problemNameController = TextEditingController(
      text: (currentData['aiProblemName'] ?? '').toString(),
    );

    final TextEditingController problemNameNeController = TextEditingController(
      text: (currentData['aiProblemNameNe'] ?? '').toString(),
    );

    final TextEditingController whatHappenedController = TextEditingController(
      text: (currentData['aiWhatHappened'] ?? '').toString(),
    );

    final TextEditingController whatHappenedNeController =
        TextEditingController(
          text: (currentData['aiWhatHappenedNe'] ?? '').toString(),
        );

    final TextEditingController treatmentController = TextEditingController(
      text: _listToLines(currentData['aiTreatmentSteps']),
    );

    final TextEditingController treatmentNeController = TextEditingController(
      text: _listToLines(currentData['aiTreatmentStepsNe']),
    );

    final TextEditingController preventionController = TextEditingController(
      text: _listToLines(currentData['aiPreventionTips']),
    );

    final TextEditingController preventionNeController = TextEditingController(
      text: _listToLines(currentData['aiPreventionTipsNe']),
    );

    final TextEditingController askExpertController = TextEditingController(
      text:
          (currentData['aiWhenToAskExpert'] ??
                  'If the problem spreads quickly, crop starts dying, or treatment does not help, contact a local agriculture expert.')
              .toString(),
    );

    final TextEditingController askExpertNeController = TextEditingController(
      text:
          (currentData['aiWhenToAskExpertNe'] ??
                  'समस्या छिटो फैलियो, बाली मर्न थाल्यो, वा उपचारले काम गरेन भने स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।')
              .toString(),
    );

    String selectedSeverity = _validSeverity(
      currentData['aiSeverity']?.toString() ?? 'Unknown',
    );
    String selectedUrgency = _validUrgency(
      currentData['aiUrgency']?.toString() ?? 'Normal',
    );
    String selectedImageQuality = _validImageQuality(
      currentData['aiImageQuality']?.toString() ?? 'Good',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                AppLanguage.text('Expert Review', 'विशेषज्ञ समीक्षा'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _sectionTitle(
                      AppLanguage.text('Review Priority', 'समीक्षा प्राथमिकता'),
                    ),
                    _dialogDropdown(
                      label: AppLanguage.text('Severity', 'गम्भीरता'),
                      value: selectedSeverity,
                      items: const ['None', 'Low', 'Medium', 'High', 'Unknown'],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedSeverity = value;
                        });
                      },
                    ),
                    _dialogDropdown(
                      label: AppLanguage.text('Urgency', 'छिटो गर्नुपर्ने'),
                      value: selectedUrgency,
                      items: const [
                        'Normal',
                        'Soon',
                        'Urgent',
                        'Upload clearer photo',
                        'Invalid photo',
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedUrgency = value;
                        });
                      },
                    ),
                    _dialogDropdown(
                      label: AppLanguage.text('Image quality', 'फोटो गुणस्तर'),
                      value: selectedImageQuality,
                      items: const [
                        'Good',
                        'Medium',
                        'Poor',
                        'Invalid',
                        'Unknown',
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedImageQuality = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(
                      AppLanguage.text('English Details', 'अंग्रेजी विवरण'),
                    ),
                    _dialogField(
                      controller: plantNameController,
                      label: 'Plant / Crop Name',
                      hint: 'Example: Tomato',
                    ),
                    _dialogField(
                      controller: affectedPartController,
                      label: 'Affected Part',
                      hint: 'Example: Leaf',
                    ),
                    _dialogField(
                      controller: problemNameController,
                      label: 'Possible Problem',
                      hint: 'Example: Early blight',
                    ),
                    _dialogField(
                      controller: whatHappenedController,
                      label: 'What happened?',
                      hint: 'Explain simply for farmer',
                      maxLines: 3,
                    ),
                    _dialogField(
                      controller: treatmentController,
                      label: 'What to do now?',
                      hint: 'Write one step per line',
                      maxLines: 4,
                    ),
                    _dialogField(
                      controller: preventionController,
                      label: 'How to prevent next time?',
                      hint: 'Write one tip per line',
                      maxLines: 4,
                    ),
                    _dialogField(
                      controller: askExpertController,
                      label: 'When to ask expert?',
                      hint: 'Write expert warning',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(
                      AppLanguage.text('Nepali Details', 'नेपाली विवरण'),
                    ),
                    _dialogField(
                      controller: plantNameNeController,
                      label: 'बिरुवा / बालीको नाम',
                      hint: 'उदाहरण: टमाटर',
                    ),
                    _dialogField(
                      controller: affectedPartNeController,
                      label: 'समस्या भएको भाग',
                      hint: 'उदाहरण: पात',
                    ),
                    _dialogField(
                      controller: problemNameNeController,
                      label: 'सम्भावित समस्या',
                      hint: 'उदाहरण: फंगल रोग',
                    ),
                    _dialogField(
                      controller: whatHappenedNeController,
                      label: 'के भएको हो?',
                      hint: 'किसानले बुझ्ने गरी सरल भाषामा लेख्नुहोस्',
                      maxLines: 3,
                    ),
                    _dialogField(
                      controller: treatmentNeController,
                      label: 'अब के गर्ने?',
                      hint: 'प्रत्येक उपाय अलग लाइनमा लेख्नुहोस्',
                      maxLines: 4,
                    ),
                    _dialogField(
                      controller: preventionNeController,
                      label: 'अर्को पटक कसरी बच्ने?',
                      hint: 'प्रत्येक सुझाव अलग लाइनमा लेख्नुहोस्',
                      maxLines: 4,
                    ),
                    _dialogField(
                      controller: askExpertNeController,
                      label: 'कहिले विशेषज्ञलाई सोध्ने?',
                      hint: 'विशेषज्ञलाई सोध्ने अवस्था लेख्नुहोस्',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(
                      AppLanguage.text('Final Comment', 'अन्तिम टिप्पणी'),
                    ),
                    _dialogField(
                      controller: commentController,
                      label: AppLanguage.text(
                        'Admin / Expert Comment',
                        'एडमिन / विशेषज्ञ टिप्पणी',
                      ),
                      hint: AppLanguage.text(
                        'Final advice or warning',
                        'अन्तिम सुझाव वा चेतावनी',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLanguage.text('Cancel', 'रद्द गर्नुहोस्')),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'plantName': plantNameController.text.trim(),
                      'plantNameNe': plantNameNeController.text.trim(),
                      'affectedPart': affectedPartController.text.trim(),
                      'affectedPartNe': affectedPartNeController.text.trim(),
                      'problemName': problemNameController.text.trim(),
                      'problemNameNe': problemNameNeController.text.trim(),
                      'severity': selectedSeverity,
                      'severityNe': _severityNe(selectedSeverity),
                      'urgency': selectedUrgency,
                      'urgencyNe': _urgencyNe(selectedUrgency),
                      'imageQuality': selectedImageQuality,
                      'imageQualityNe': _imageQualityNe(selectedImageQuality),
                      'whatHappened': whatHappenedController.text.trim(),
                      'whatHappenedNe': whatHappenedNeController.text.trim(),
                      'treatmentSteps': _linesToList(treatmentController.text),
                      'treatmentStepsNe': _linesToList(
                        treatmentNeController.text,
                      ),
                      'preventionTips': _linesToList(preventionController.text),
                      'preventionTipsNe': _linesToList(
                        preventionNeController.text,
                      ),
                      'askExpert': askExpertController.text.trim(),
                      'askExpertNe': askExpertNeController.text.trim(),
                      'comment': commentController.text.trim(),
                    });
                  },
                  child: Text(
                    AppLanguage.text('Save Review', 'समीक्षा सेभ गर्नुहोस्'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('cropReports')
          .doc(docId)
          .update({
            'status': 'reviewed',
            'adminComment': result['comment'],
            'aiStatus': 'processed',
            'aiPlantName': result['plantName'],
            'aiPlantNameNe': result['plantNameNe'],
            'aiAffectedPart': result['affectedPart'],
            'aiAffectedPartNe': result['affectedPartNe'],
            'aiProblemName': result['problemName'],
            'aiProblemNameNe': result['problemNameNe'],
            'aiProblemType': 'Expert review',
            'aiProblemTypeNe': 'विशेषज्ञ समीक्षा',
            'aiConfidence': 100,
            'aiSeverity': result['severity'],
            'aiSeverityNe': result['severityNe'],
            'aiUrgency': result['urgency'],
            'aiUrgencyNe': result['urgencyNe'],
            'aiImageQuality': result['imageQuality'],
            'aiImageQualityNe': result['imageQualityNe'],
            'aiWhatHappened': result['whatHappened'],
            'aiWhatHappenedNe': result['whatHappenedNe'],
            'aiWhyItHappened': '',
            'aiWhyItHappenedNe': '',
            'aiTreatmentSteps': result['treatmentSteps'],
            'aiTreatmentStepsNe': result['treatmentStepsNe'],
            'aiPreventionTips': result['preventionTips'],
            'aiPreventionTipsNe': result['preventionTipsNe'],
            'aiWhenToAskExpert': result['askExpert'],
            'aiWhenToAskExpertNe': result['askExpertNe'],
            'expertVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _createFarmerNotification(
        reportData: currentData,
        reviewResult: result,
        reportId: docId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLanguage.text(
                'Report reviewed successfully ✅',
                'रिपोर्ट सफलतापूर्वक समीक्षा भयो ✅',
              ),
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLanguage.text(
                'Failed to review report: $e',
                'रिपोर्ट समीक्षा गर्न समस्या भयो: $e',
              ),
            ),
          ),
        );
      }
    }
  }

  static String _validSeverity(String value) {
    const allowed = ['None', 'Low', 'Medium', 'High', 'Unknown'];
    return allowed.contains(value) ? value : 'Unknown';
  }

  static String _validUrgency(String value) {
    const allowed = [
      'Normal',
      'Soon',
      'Urgent',
      'Upload clearer photo',
      'Invalid photo',
    ];
    return allowed.contains(value) ? value : 'Normal';
  }

  static String _validImageQuality(String value) {
    const allowed = ['Good', 'Medium', 'Poor', 'Invalid', 'Unknown'];
    return allowed.contains(value) ? value : 'Good';
  }

  static String _severityNe(String value) {
    if (value == 'None') return 'समस्या देखिएन';
    if (value == 'Low') return 'कम';
    if (value == 'Medium') return 'मध्यम';
    if (value == 'High') return 'उच्च';
    return 'थाहा छैन';
  }

  static String _urgencyNe(String value) {
    if (value == 'Normal') return 'सामान्य';
    if (value == 'Soon') return 'चाँडै';
    if (value == 'Urgent') return 'जरुरी';
    if (value == 'Upload clearer photo') return 'अझ सफा फोटो अपलोड गर्नुहोस्';
    if (value == 'Invalid photo') return 'गलत फोटो';
    return 'सामान्य';
  }

  static String _imageQualityNe(String value) {
    if (value == 'Good') return 'राम्रो';
    if (value == 'Medium') return 'मध्यम';
    if (value == 'Poor') return 'कमजोर';
    if (value == 'Invalid') return 'गलत फोटो';
    return 'थाहा छैन';
  }

  static Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  static Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  static Widget _dialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  static String _listToLines(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).join('\n');
    }

    return '';
  }

  static List<String> _linesToList(String value) {
    return value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  String _displayText(String english, String nepali) {
    if (AppLanguage.isNepali && nepali.trim().isNotEmpty) {
      return nepali;
    }

    return english;
  }

  List<String> _displayList(List<String> english, List<String> nepali) {
    if (AppLanguage.isNepali && nepali.isNotEmpty) {
      return nepali;
    }

    return english;
  }

  String _translateFarmerNote(String note) {
    if (!AppLanguage.isNepali) return note;

    String translated = note;

    final symptomMap = {
      'Yellow leaves': 'पात पहेँलो',
      'Brown spots': 'खैरो दाग',
      'White powder': 'सेतो धुलो',
      'Insects or holes': 'किरा वा प्वाल',
      'Drying or wilting': 'सुक्ने वा ओइलाउने',
      'Symptoms': 'लक्षण',
    };

    symptomMap.forEach((english, nepali) {
      translated = translated.replaceAll(english, nepali);
    });

    return translated;
  }

  String _formatStatus(String status) {
    if (status == 'pending_review') {
      return AppLanguage.text('Waiting for Review', 'समीक्षाको प्रतीक्षामा');
    }

    if (status == 'reviewed') {
      return AppLanguage.text('Expert Reviewed', 'विशेषज्ञद्वारा समीक्षा भएको');
    }

    return status;
  }

  String _formatAiStatus(String status) {
    if (status == 'not_processed') {
      return AppLanguage.text('AI not checked yet', 'एआईले अझै जाँच गरेको छैन');
    }

    if (status == 'processed') {
      return AppLanguage.text('Diagnosis added', 'निदान थपियो');
    }

    if (status == 'failed') {
      return AppLanguage.text('AI check failed', 'एआई जाँच असफल भयो');
    }

    return status;
  }

  String _imageUploadStatusText(String status) {
    if (status == 'not_uploaded_yet') {
      return AppLanguage.text(
        'Image upload is not connected yet.',
        'फोटो अपलोड अझै जोडिएको छैन।',
      );
    }

    if (status == 'uploading') {
      return AppLanguage.text('Image is uploading...', 'फोटो अपलोड हुँदैछ...');
    }

    if (status == 'uploaded') {
      return AppLanguage.text(
        'Image uploaded successfully.',
        'फोटो सफलतापूर्वक अपलोड भयो।',
      );
    }

    if (status == 'failed') {
      return AppLanguage.text('Image upload failed.', 'फोटो अपलोड असफल भयो।');
    }

    return status;
  }

  String _backendAiStatusText(String status, String message, String messageNe) {
    if (status == 'not_connected') {
      return AppLanguage.text(
        message.trim().isNotEmpty ? message : 'AI check is not connected yet.',
        messageNe.trim().isNotEmpty ? messageNe : 'एआई जाँच अझै जोडिएको छैन।',
      );
    }

    if (status == 'scanning') {
      return AppLanguage.text(
        'AI is checking your plant photo...',
        'एआईले तपाईंको बिरुवाको फोटो जाँच गर्दैछ...',
      );
    }

    if (status == 'completed') {
      if (message.trim().isNotEmpty || messageNe.trim().isNotEmpty) {
        return AppLanguage.text(
          message.trim().isNotEmpty
              ? message
              : 'Plant image checked successfully.',
          messageNe.trim().isNotEmpty
              ? messageNe
              : 'बिरुवाको फोटो सफलतापूर्वक जाँच भयो।',
        );
      }

      return AppLanguage.text(
        'Plant image checked successfully.',
        'बिरुवाको फोटो सफलतापूर्वक जाँच भयो।',
      );
    }

    if (status == 'failed') {
      return AppLanguage.text(
        message.trim().isNotEmpty ? message : 'AI check failed.',
        messageNe.trim().isNotEmpty ? messageNe : 'एआई जाँच असफल भयो।',
      );
    }

    return status;
  }

  Color _statusColor(String status) {
    if (status == 'reviewed') return Colors.green;
    return Colors.orange;
  }

  Color _severityColor(String severity) {
    final value = severity.toLowerCase();

    if (value == 'high') return Colors.red;
    if (value == 'medium') return Colors.orange;
    if (value == 'low') return Colors.amber;
    if (value == 'none') return Colors.green;

    return Colors.grey;
  }

  Color _urgencyColor(String urgency) {
    final value = urgency.toLowerCase();

    if (value == 'urgent') return Colors.red;
    if (value == 'soon') return Colors.orange;
    if (value == 'normal') return Colors.green;
    if (value == 'upload clearer photo') return Colors.blue;
    if (value == 'invalid photo') return Colors.red;

    return Colors.grey;
  }

  Color _imageQualityColor(String quality) {
    final value = quality.toLowerCase();

    if (value == 'good') return Colors.green;
    if (value == 'medium') return Colors.orange;
    if (value == 'poor') return Colors.red;
    if (value == 'invalid') return Colors.red;

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final farmerNote = data['farmerNote'] ?? data['description'] ?? '';
    final userEmail = data['userEmail'] ?? 'No email';

    final status = data['status'] ?? 'pending_review';
    final aiStatus = data['aiStatus'] ?? 'not_processed';
    final adminComment = data['adminComment'] ?? '';
    final expertVerified = data['expertVerified'] ?? false;

    final imageUploadStatus = data['imageUploadStatus'] ?? 'not_uploaded_yet';
    final imageUrl = data['imageUrl'] ?? '';

    final backendAiStatus = data['backendAiStatus'] ?? 'not_connected';
    final backendAiMessage = data['backendAiMessage'] ?? '';
    final backendAiMessageNe = data['backendAiMessageNe'] ?? '';

    final plantName = _displayText(
      (data['aiPlantName'] ?? '').toString(),
      (data['aiPlantNameNe'] ?? '').toString(),
    );

    final affectedPart = _displayText(
      (data['aiAffectedPart'] ?? '').toString(),
      (data['aiAffectedPartNe'] ?? '').toString(),
    );

    final problemName = _displayText(
      (data['aiProblemName'] ?? '').toString(),
      (data['aiProblemNameNe'] ?? '').toString(),
    );

    final problemType = _displayText(
      (data['aiProblemType'] ?? '').toString(),
      (data['aiProblemTypeNe'] ?? '').toString(),
    );

    final severity = _displayText(
      (data['aiSeverity'] ?? '').toString(),
      (data['aiSeverityNe'] ?? '').toString(),
    );

    final urgency = _displayText(
      (data['aiUrgency'] ?? '').toString(),
      (data['aiUrgencyNe'] ?? '').toString(),
    );

    final imageQuality = _displayText(
      (data['aiImageQuality'] ?? '').toString(),
      (data['aiImageQualityNe'] ?? '').toString(),
    );

    final severityEnglish = data['aiSeverity'] ?? '';
    final urgencyEnglish = data['aiUrgency'] ?? '';
    final imageQualityEnglish = data['aiImageQuality'] ?? '';

    final whatHappened = _displayText(
      (data['aiWhatHappened'] ?? '').toString(),
      (data['aiWhatHappenedNe'] ?? '').toString(),
    );

    final whyItHappened = _displayText(
      (data['aiWhyItHappened'] ?? '').toString(),
      (data['aiWhyItHappenedNe'] ?? '').toString(),
    );

    final treatmentSteps = _displayList(
      _toStringList(data['aiTreatmentSteps']),
      _toStringList(data['aiTreatmentStepsNe']),
    );

    final preventionTips = _displayList(
      _toStringList(data['aiPreventionTips']),
      _toStringList(data['aiPreventionTipsNe']),
    );

    final whenToAskExpert = _displayText(
      (data['aiWhenToAskExpert'] ?? '').toString(),
      (data['aiWhenToAskExpertNe'] ?? '').toString(),
    );

    final confidence = data['aiConfidence'] ?? 0;
    final color = _statusColor(status.toString());

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Admin Report Details', 'एडमिन रिपोर्ट विवरण'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(
                  status: status.toString(),
                  aiStatus: aiStatus.toString(),
                  expertVerified: expertVerified == true,
                  color: color,
                ),
                const SizedBox(height: 14),
                _infoBox(
                  Icons.email,
                  AppLanguage.text('Farmer', 'किसान'),
                  userEmail.toString(),
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _infoBox(
                  Icons.edit_note,
                  AppLanguage.text('Farmer note', 'किसानको नोट'),
                  farmerNote.toString().trim().isEmpty
                      ? AppLanguage.text('No note added', 'नोट थपिएको छैन')
                      : _translateFarmerNote(farmerNote.toString()),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _infoBox(
                  Icons.image,
                  AppLanguage.text('Image upload', 'फोटो अपलोड'),
                  _imageUploadStatusText(imageUploadStatus.toString()),
                  Colors.teal,
                ),
                if (imageUrl.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl.toString(),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _infoBox(
                          Icons.broken_image,
                          AppLanguage.text('Image error', 'फोटो समस्या'),
                          AppLanguage.text(
                            'Could not load uploaded image.',
                            'अपलोड गरिएको फोटो लोड हुन सकेन।',
                          ),
                          Colors.red,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _infoBox(
                  Icons.memory,
                  AppLanguage.text('AI Check', 'एआई जाँच'),
                  _backendAiStatusText(
                    backendAiStatus.toString(),
                    backendAiMessage.toString(),
                    backendAiMessageNe.toString(),
                  ),
                  Colors.indigo,
                ),
                const SizedBox(height: 16),
                _diagnosisBox(
                  plantName: plantName,
                  affectedPart: affectedPart,
                  problemName: problemName,
                  problemType: problemType,
                  confidence: confidence,
                  severity: severity,
                  urgency: urgency,
                  imageQuality: imageQuality,
                  severityColor: _severityColor(severityEnglish.toString()),
                  urgencyColor: _urgencyColor(urgencyEnglish.toString()),
                  imageQualityColor: _imageQualityColor(
                    imageQualityEnglish.toString(),
                  ),
                  whatHappened: whatHappened,
                  whyItHappened: whyItHappened,
                  treatmentSteps: treatmentSteps,
                  preventionTips: preventionTips,
                  whenToAskExpert: whenToAskExpert,
                ),
                const SizedBox(height: 16),
                _infoBox(
                  Icons.support_agent,
                  AppLanguage.text('Admin comment', 'एडमिन टिप्पणी'),
                  adminComment.toString().trim().isEmpty
                      ? AppLanguage.text(
                          'No admin comment yet',
                          'अहिले सम्म एडमिन टिप्पणी छैन',
                        )
                      : adminComment.toString(),
                  Colors.orange,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewReport(context, docId, data),
                    icon: const Icon(Icons.rate_review),
                    label: Text(
                      status == 'reviewed'
                          ? AppLanguage.text(
                              'Update Review',
                              'समीक्षा अपडेट गर्नुहोस्',
                            )
                          : AppLanguage.text(
                              'Review Report',
                              'रिपोर्ट समीक्षा गर्नुहोस्',
                            ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard({
    required String status,
    required String aiStatus,
    required bool expertVerified,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.text('Plant Problem Report', 'बिरुवा समस्या रिपोर्ट'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusChip(_formatStatus(status), color),
              _statusChip(_formatAiStatus(aiStatus), Colors.blue),
              if (expertVerified)
                _statusChip(
                  AppLanguage.text(
                    'Expert verified',
                    'विशेषज्ञले पुष्टि गरेको',
                  ),
                  Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _diagnosisBox({
    required String plantName,
    required String affectedPart,
    required String problemName,
    required String problemType,
    required dynamic confidence,
    required String severity,
    required String urgency,
    required String imageQuality,
    required Color severityColor,
    required Color urgencyColor,
    required Color imageQualityColor,
    required String whatHappened,
    required String whyItHappened,
    required List<String> treatmentSteps,
    required List<String> preventionTips,
    required String whenToAskExpert,
  }) {
    final hasDiagnosis =
        plantName.trim().isNotEmpty ||
        affectedPart.trim().isNotEmpty ||
        problemName.trim().isNotEmpty ||
        treatmentSteps.isNotEmpty ||
        preventionTips.isNotEmpty;

    if (!hasDiagnosis) {
      return _infoBox(
        Icons.hourglass_bottom,
        AppLanguage.text('Diagnosis pending', 'निदान बाँकी छ'),
        AppLanguage.text(
          'Diagnosis/advice will appear here after expert review.',
          'विशेषज्ञ समीक्षा पछि निदान/सुझाव यहाँ देखिनेछ।',
        ),
        Colors.blue,
      );
    }

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
          Text(
            AppLanguage.text('Diagnosis / Advice', 'निदान / सुझाव'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 10),
          if (plantName.trim().isNotEmpty)
            _smallLine(
              Icons.local_florist,
              AppLanguage.text('Plant', 'बिरुवा'),
              plantName,
            ),
          if (affectedPart.trim().isNotEmpty)
            _smallLine(
              Icons.eco,
              AppLanguage.text('Affected part', 'समस्या भएको भाग'),
              affectedPart,
            ),
          if (problemName.trim().isNotEmpty)
            _smallLine(
              Icons.bug_report,
              AppLanguage.text('Problem', 'समस्या'),
              problemName,
            ),
          if (problemType.trim().isNotEmpty)
            _smallLine(
              Icons.category,
              AppLanguage.text('Problem type', 'समस्या प्रकार'),
              problemType,
            ),
          if (confidence.toString() != '0')
            _smallLine(
              Icons.analytics,
              AppLanguage.text('Confidence', 'विश्वास स्तर'),
              '$confidence%',
            ),
          if (severity.trim().isNotEmpty ||
              urgency.trim().isNotEmpty ||
              imageQuality.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (severity.trim().isNotEmpty)
                  _infoChip(
                    AppLanguage.text('Severity', 'गम्भीरता'),
                    severity,
                    severityColor,
                  ),
                if (urgency.trim().isNotEmpty)
                  _infoChip(
                    AppLanguage.text('Urgency', 'छिटो गर्नुपर्ने'),
                    urgency,
                    urgencyColor,
                  ),
                if (imageQuality.trim().isNotEmpty)
                  _infoChip(
                    AppLanguage.text('Image quality', 'फोटो गुणस्तर'),
                    imageQuality,
                    imageQualityColor,
                  ),
              ],
            ),
          ],
          if (whatHappened.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppLanguage.text('What happened?', 'के भएको हो?'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(whatHappened),
          ],
          if (whyItHappened.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppLanguage.text('Why it may happen?', 'किन यस्तो हुन सक्छ?'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(whyItHappened),
          ],
          if (treatmentSteps.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppLanguage.text('Treatment steps:', 'उपचारका उपाय:'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...treatmentSteps.map((step) => Text('• $step')),
          ],
          if (preventionTips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppLanguage.text('Prevention tips:', 'बच्ने उपाय:'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...preventionTips.map((tip) => Text('• $tip')),
          ],
          if (whenToAskExpert.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppLanguage.text(
                'When should farmer ask expert?',
                'किसानले कहिले विशेषज्ञलाई सोध्ने?',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(whenToAskExpert),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
