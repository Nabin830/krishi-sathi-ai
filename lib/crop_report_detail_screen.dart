import 'package:flutter/material.dart';

import 'app_language.dart';

class CropReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const CropReportDetailScreen({super.key, required this.data});

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
      return AppLanguage.text('Waiting for review', 'समीक्षाको प्रतीक्षामा');
    }

    if (status == 'reviewed') {
      return AppLanguage.text(
        'Checked by expert',
        'विशेषज्ञद्वारा जाँच गरिएको',
      );
    }

    return status;
  }

  String _formatAiStatus(String status) {
    if (status == 'not_processed') {
      return AppLanguage.text(
        'Diagnosis not added yet',
        'निदान अझै थपिएको छैन',
      );
    }

    if (status == 'processed') {
      return AppLanguage.text('Diagnosis added', 'निदान थपियो');
    }

    if (status == 'failed') {
      return AppLanguage.text('Diagnosis failed', 'निदान असफल भयो');
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
        message.trim().isNotEmpty
            ? message
            : 'Backend AI is not connected yet.',
        messageNe.trim().isNotEmpty
            ? messageNe
            : 'ब्याकएन्ड एआई अझै जोडिएको छैन।',
      );
    }

    if (status == 'scanning') {
      return AppLanguage.text(
        'Backend AI is scanning your plant photo...',
        'ब्याकएन्ड एआईले तपाईंको बिरुवाको फोटो जाँच गर्दैछ...',
      );
    }

    if (status == 'completed') {
      if (message.trim().isNotEmpty || messageNe.trim().isNotEmpty) {
        return AppLanguage.text(
          message.trim().isNotEmpty ? message : 'Backend AI scan completed.',
          messageNe.trim().isNotEmpty
              ? messageNe
              : 'ब्याकएन्ड एआई जाँच पूरा भयो।',
        );
      }

      return AppLanguage.text(
        'Backend AI scan completed.',
        'ब्याकएन्ड एआई जाँच पूरा भयो।',
      );
    }

    if (status == 'failed') {
      return AppLanguage.text(
        message.trim().isNotEmpty ? message : 'Backend AI scan failed.',
        messageNe.trim().isNotEmpty
            ? messageNe
            : 'ब्याकएन्ड एआई जाँच असफल भयो।',
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
    final status = data['status'] ?? 'pending_review';
    final aiStatus = data['aiStatus'] ?? 'not_processed';
    final imageUploadStatus = data['imageUploadStatus'] ?? 'not_uploaded_yet';
    final imageUrl = data['imageUrl'] ?? '';

    final backendAiStatus = data['backendAiStatus'] ?? 'not_connected';
    final backendAiMessage = data['backendAiMessage'] ?? '';
    final backendAiMessageNe = data['backendAiMessageNe'] ?? '';

    final adminComment = data['adminComment'] ?? '';
    final expertVerified = data['expertVerified'] ?? false;

    final plantName = _displayText(
      data['aiPlantName'] ?? '',
      data['aiPlantNameNe'] ?? '',
    );

    final affectedPart = _displayText(
      data['aiAffectedPart'] ?? '',
      data['aiAffectedPartNe'] ?? '',
    );

    final problemName = _displayText(
      data['aiProblemName'] ?? '',
      data['aiProblemNameNe'] ?? '',
    );

    final problemType = _displayText(
      data['aiProblemType'] ?? '',
      data['aiProblemTypeNe'] ?? '',
    );

    final severity = _displayText(
      data['aiSeverity'] ?? '',
      data['aiSeverityNe'] ?? '',
    );

    final urgency = _displayText(
      data['aiUrgency'] ?? '',
      data['aiUrgencyNe'] ?? '',
    );

    final imageQuality = _displayText(
      data['aiImageQuality'] ?? '',
      data['aiImageQualityNe'] ?? '',
    );

    final severityEnglish = data['aiSeverity'] ?? '';
    final urgencyEnglish = data['aiUrgency'] ?? '';
    final imageQualityEnglish = data['aiImageQuality'] ?? '';

    final whatHappened = _displayText(
      data['aiWhatHappened'] ?? '',
      data['aiWhatHappenedNe'] ?? '',
    );

    final whyItHappened = _displayText(
      data['aiWhyItHappened'] ?? '',
      data['aiWhyItHappenedNe'] ?? '',
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
      data['aiWhenToAskExpert'] ?? '',
      data['aiWhenToAskExpertNe'] ?? '',
    );

    final confidence = data['aiConfidence'] ?? 0;

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Report Details', 'रिपोर्ट विवरण'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(status, aiStatus, expertVerified),
                const SizedBox(height: 16),

                if (expertVerified == true) ...[
                  _expertVerifiedBanner(),
                  const SizedBox(height: 12),
                ] else ...[
                  _waitingReviewBanner(),
                  const SizedBox(height: 12),
                ],

                _infoBox(
                  icon: Icons.edit_note,
                  title: AppLanguage.text('Your note', 'तपाईंको नोट'),
                  text: farmerNote.toString().trim().isEmpty
                      ? AppLanguage.text('No note added', 'नोट थपिएको छैन')
                      : _translateFarmerNote(farmerNote.toString()),
                  color: Colors.blue,
                ),

                const SizedBox(height: 12),

                _infoBox(
                  icon: Icons.image,
                  title: AppLanguage.text('Image upload', 'फोटो अपलोड'),
                  text: _imageUploadStatusText(imageUploadStatus.toString()),
                  color: Colors.teal,
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
                          icon: Icons.broken_image,
                          title: AppLanguage.text('Image error', 'फोटो समस्या'),
                          text: AppLanguage.text(
                            'Could not load uploaded image.',
                            'अपलोड गरिएको फोटो लोड हुन सकेन।',
                          ),
                          color: Colors.red,
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                _infoBox(
                  icon: Icons.memory,
                  title: AppLanguage.text('Backend AI', 'ब्याकएन्ड एआई'),
                  text: _backendAiStatusText(
                    backendAiStatus.toString(),
                    backendAiMessage.toString(),
                    backendAiMessageNe.toString(),
                  ),
                  color: Colors.indigo,
                ),

                const SizedBox(height: 16),

                _diagnosisCard(
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
                  icon: Icons.support_agent,
                  title: AppLanguage.text(
                    'Expert/Admin comment',
                    'विशेषज्ञ/एडमिन टिप्पणी',
                  ),
                  text: adminComment.toString().trim().isNotEmpty
                      ? adminComment.toString()
                      : AppLanguage.text(
                          'Not reviewed yet. Please wait for expert/admin advice.',
                          'अहिले सम्म समीक्षा भएको छैन। कृपया विशेषज्ञ/एडमिन सुझावको प्रतीक्षा गर्नुहोस्।',
                        ),
                  color: adminComment.toString().trim().isNotEmpty
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _expertVerifiedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(Icons.verified, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(
                    'Expert Verified',
                    'विशेषज्ञले पुष्टि गरेको',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLanguage.text(
                    'This report has been checked by an admin/expert. You can follow the reviewed advice below.',
                    'यो रिपोर्ट एडमिन/विशेषज्ञले जाँच गरेको छ। तलको समीक्षा गरिएको सुझाव हेर्नुहोस्।',
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waitingReviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.hourglass_bottom, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.text(
                    'Waiting for Expert Review',
                    'विशेषज्ञ समीक्षाको प्रतीक्षामा',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLanguage.text(
                    'AI result is available, but admin/expert review has not been completed yet.',
                    'एआई नतिजा उपलब्ध छ, तर एडमिन/विशेषज्ञ समीक्षा अझै पूरा भएको छैन।',
                  ),
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(String status, String aiStatus, bool expertVerified) {
    final color = _statusColor(status);

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
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.assignment, color: Colors.green, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  AppLanguage.text(
                    'Plant Problem Report',
                    'बिरुवा समस्या रिपोर्ट',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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

  Widget _diagnosisCard({
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
        problemName.trim().isNotEmpty ||
        treatmentSteps.isNotEmpty ||
        preventionTips.isNotEmpty;

    if (!hasDiagnosis) {
      return _infoBox(
        icon: Icons.hourglass_bottom,
        title: AppLanguage.text('Diagnosis pending', 'निदान बाँकी छ'),
        text: AppLanguage.text(
          'Your report is saved. Diagnosis/advice will appear here after AI or expert review.',
          'तपाईंको रिपोर्ट सेभ भयो। एआई वा विशेषज्ञ समीक्षा पछि निदान/सुझाव यहाँ देखिनेछ।',
        ),
        color: Colors.blue,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        color: Colors.green.shade50,
        borderColor: Colors.green.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.psychology_alt,
            AppLanguage.text('Plant Check Result', 'बिरुवा जाँच नतिजा'),
          ),
          const SizedBox(height: 12),

          _resultLine(
            Icons.local_florist,
            AppLanguage.text('Plant', 'बिरुवा'),
            plantName.trim().isEmpty
                ? AppLanguage.text('Not sure', 'निश्चित छैन')
                : plantName,
          ),
          _resultLine(
            Icons.eco,
            AppLanguage.text('Affected part', 'समस्या भएको भाग'),
            affectedPart.trim().isEmpty
                ? AppLanguage.text('Not sure', 'निश्चित छैन')
                : affectedPart,
          ),
          _resultLine(
            Icons.bug_report,
            AppLanguage.text('Possible problem', 'सम्भावित समस्या'),
            problemName.trim().isEmpty
                ? AppLanguage.text('Not sure', 'निश्चित छैन')
                : problemName,
          ),

          if (problemType.trim().isNotEmpty)
            _resultLine(
              Icons.category,
              AppLanguage.text('Problem type', 'समस्या प्रकार'),
              problemType,
            ),

          if (confidence.toString() != '0')
            _resultLine(
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

          if (whatHappened.trim().isNotEmpty)
            _detailSection(
              Icons.help_outline,
              AppLanguage.text('What happened?', 'के भएको हो?'),
              Text(whatHappened),
            ),

          if (whyItHappened.trim().isNotEmpty)
            _detailSection(
              Icons.info_outline,
              AppLanguage.text('Why it may happen?', 'किन यस्तो हुन सक्छ?'),
              Text(whyItHappened),
            ),

          if (treatmentSteps.isNotEmpty)
            _detailSection(
              Icons.healing,
              AppLanguage.text(
                'What should I do now?',
                'अब मैले के गर्नुपर्छ?',
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: treatmentSteps.map((step) {
                  return _bulletText(step);
                }).toList(),
              ),
            ),

          if (preventionTips.isNotEmpty)
            _detailSection(
              Icons.shield,
              AppLanguage.text(
                'How to prevent next time?',
                'अर्को पटक कसरी बच्ने?',
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: preventionTips.map((tip) {
                  return _bulletText(tip);
                }).toList(),
              ),
            ),

          if (whenToAskExpert.trim().isNotEmpty)
            _detailSection(
              Icons.warning_amber,
              AppLanguage.text(
                'When should I ask an expert?',
                'कहिले विशेषज्ञलाई सोध्ने?',
              ),
              Text(whenToAskExpert),
            ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        color: color.withOpacity(0.08),
        borderColor: color.withOpacity(0.16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
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

  Widget _detailSection(IconData icon, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(
          color: Colors.white,
          borderColor: Colors.green.shade100,
          shadow: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeading(icon, title),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.green.shade700),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _resultLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
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

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
    Color? borderColor,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: borderColor == null ? null : Border.all(color: borderColor),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );
  }
}
