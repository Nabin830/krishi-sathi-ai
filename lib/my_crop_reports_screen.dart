import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';
import 'crop_report_detail_screen.dart';

class MyCropReportsScreen extends StatefulWidget {
  const MyCropReportsScreen({super.key});

  @override
  State<MyCropReportsScreen> createState() => _MyCropReportsScreenState();
}

class _MyCropReportsScreenState extends State<MyCropReportsScreen> {
  String _selectedFilter = 'all';

  Future<void> _deleteReport(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLanguage.text('Delete Report', 'रिपोर्ट हटाउने')),
          content: Text(
            AppLanguage.text(
              'Are you sure you want to delete this plant problem report?',
              'के तपाईं यो बिरुवा समस्या रिपोर्ट हटाउन चाहनुहुन्छ?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLanguage.text('Cancel', 'रद्द गर्नुहोस्')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLanguage.text('Delete', 'हटाउनुहोस्')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('cropReports')
          .doc(docId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLanguage.text(
                'Report deleted successfully ✅',
                'रिपोर्ट सफलतापूर्वक हटाइयो ✅',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLanguage.text(
                'Failed to delete report: $e',
                'रिपोर्ट हटाउन समस्या भयो: $e',
              ),
            ),
          ),
        );
      }
    }
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

  Color _statusColor(String status) {
    if (status == 'reviewed') return Colors.green;
    return Colors.orange;
  }

  String _displayText(String english, String nepali) {
    if (AppLanguage.isNepali && nepali.trim().isNotEmpty) {
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

  int _urgencyRank(String urgency) {
    final value = urgency.toLowerCase();

    if (value == 'urgent') return 5;
    if (value == 'soon') return 4;
    if (value == 'upload clearer photo') return 3;
    if (value == 'invalid photo') return 2;
    if (value == 'normal') return 1;

    return 0;
  }

  int _severityRank(String severity) {
    final value = severity.toLowerCase();

    if (value == 'high') return 5;
    if (value == 'medium') return 4;
    if (value == 'low') return 3;
    if (value == 'unknown') return 2;
    if (value == 'none') return 1;

    return 0;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  bool _passesFilter(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final urgency = (data['aiUrgency'] ?? '').toString().toLowerCase();
    final severity = (data['aiSeverity'] ?? '').toString().toLowerCase();

    if (_selectedFilter == 'pending') {
      return status == 'pending_review';
    }

    if (_selectedFilter == 'reviewed') {
      return status == 'reviewed';
    }

    if (_selectedFilter == 'urgent') {
      return urgency == 'urgent' || urgency == 'soon';
    }

    if (_selectedFilter == 'serious') {
      return severity == 'high' || severity == 'medium';
    }

    return true;
  }

  void _sortReports(List<QueryDocumentSnapshot> reports) {
    if (_selectedFilter == 'urgent') {
      reports.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        final rankA = _urgencyRank((dataA['aiUrgency'] ?? '').toString());
        final rankB = _urgencyRank((dataB['aiUrgency'] ?? '').toString());

        return rankB.compareTo(rankA);
      });
      return;
    }

    if (_selectedFilter == 'serious') {
      reports.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;

        final rankA = _severityRank((dataA['aiSeverity'] ?? '').toString());
        final rankB = _severityRank((dataB['aiSeverity'] ?? '').toString());

        return rankB.compareTo(rankA);
      });
    }
  }

  int _countPending(List<QueryDocumentSnapshot> reports) {
    return reports.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['status'] ?? '').toString() == 'pending_review';
    }).length;
  }

  int _countReviewed(List<QueryDocumentSnapshot> reports) {
    return reports.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['status'] ?? '').toString() == 'reviewed';
    }).length;
  }

  int _countUrgentOrSoon(List<QueryDocumentSnapshot> reports) {
    return reports.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final urgency = (data['aiUrgency'] ?? '').toString().toLowerCase();
      return urgency == 'urgent' || urgency == 'soon';
    }).length;
  }

  int _countSerious(List<QueryDocumentSnapshot> reports) {
    return reports.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final severity = (data['aiSeverity'] ?? '').toString().toLowerCase();
      return severity == 'high' || severity == 'medium';
    }).length;
  }

  Map<String, dynamic> _buildDetailData(Map<String, dynamic> data) {
    return {
      'farmerNote': data['farmerNote'] ?? data['description'] ?? '',
      'status': data['status'] ?? 'pending_review',
      'adminComment': data['adminComment'] ?? '',
      'imageUploadStatus': data['imageUploadStatus'] ?? 'not_uploaded_yet',
      'imageUrl': data['imageUrl'] ?? '',

      'backendAiStatus': data['backendAiStatus'] ?? 'not_connected',
      'backendAiMessage': data['backendAiMessage'] ?? '',
      'backendAiMessageNe': data['backendAiMessageNe'] ?? '',

      'aiStatus': data['aiStatus'] ?? 'not_processed',
      'aiPlantName': data['aiPlantName'] ?? '',
      'aiPlantNameNe': data['aiPlantNameNe'] ?? '',
      'aiAffectedPart': data['aiAffectedPart'] ?? '',
      'aiAffectedPartNe': data['aiAffectedPartNe'] ?? '',
      'aiProblemName': data['aiProblemName'] ?? '',
      'aiProblemNameNe': data['aiProblemNameNe'] ?? '',
      'aiProblemType': data['aiProblemType'] ?? '',
      'aiProblemTypeNe': data['aiProblemTypeNe'] ?? '',
      'aiConfidence': data['aiConfidence'] ?? 0,

      'aiSeverity': data['aiSeverity'] ?? '',
      'aiSeverityNe': data['aiSeverityNe'] ?? '',
      'aiUrgency': data['aiUrgency'] ?? '',
      'aiUrgencyNe': data['aiUrgencyNe'] ?? '',
      'aiImageQuality': data['aiImageQuality'] ?? '',
      'aiImageQualityNe': data['aiImageQualityNe'] ?? '',

      'aiWhatHappened': data['aiWhatHappened'] ?? '',
      'aiWhatHappenedNe': data['aiWhatHappenedNe'] ?? '',
      'aiWhyItHappened': data['aiWhyItHappened'] ?? '',
      'aiWhyItHappenedNe': data['aiWhyItHappenedNe'] ?? '',
      'aiTreatmentSteps': _toStringList(data['aiTreatmentSteps']),
      'aiTreatmentStepsNe': _toStringList(data['aiTreatmentStepsNe']),
      'aiPreventionTips': _toStringList(data['aiPreventionTips']),
      'aiPreventionTipsNe': _toStringList(data['aiPreventionTipsNe']),
      'aiWhenToAskExpert': data['aiWhenToAskExpert'] ?? '',
      'aiWhenToAskExpertNe': data['aiWhenToAskExpertNe'] ?? '',
      'expertVerified': data['expertVerified'] ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            AppLanguage.text(
              'You must be logged in',
              'तपाईं लगइन भएको हुनुपर्छ',
            ),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('My Plant Reports', 'मेरो बिरुवा रिपोर्ट'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cropReports')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${AppLanguage.text('Error', 'त्रुटि')}: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState();
                }

                final allReports = snapshot.data!.docs;

                final filteredReports = allReports.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _passesFilter(data);
                }).toList();

                _sortReports(filteredReports);

                final totalCount = allReports.length;
                final pendingCount = _countPending(allReports);
                final reviewedCount = _countReviewed(allReports);
                final urgentSoonCount = _countUrgentOrSoon(allReports);
                final seriousCount = _countSerious(allReports);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(
                      totalCount: totalCount,
                      showingCount: filteredReports.length,
                    ),
                    const SizedBox(height: 14),
                    _summaryDashboard(
                      totalCount: totalCount,
                      pendingCount: pendingCount,
                      reviewedCount: reviewedCount,
                      urgentSoonCount: urgentSoonCount,
                      seriousCount: seriousCount,
                    ),
                    const SizedBox(height: 18),
                    if (filteredReports.isEmpty)
                      _filteredEmptyState()
                    else
                      ...filteredReports.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final farmerNote =
                            data['farmerNote'] ??
                            data['description'] ??
                            AppLanguage.text('No note added', 'नोट थपिएको छैन');

                        final status = data['status'] ?? 'pending_review';
                        final aiStatus = data['aiStatus'] ?? 'not_processed';
                        final expertVerified = data['expertVerified'] ?? false;

                        final displayProblemName = _displayText(
                          data['aiProblemName'] ?? '',
                          data['aiProblemNameNe'] ?? '',
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
                        final imageQualityEnglish =
                            data['aiImageQuality'] ?? '';

                        final detailData = _buildDetailData(data);

                        return _reportCard(
                          context: context,
                          docId: doc.id,
                          farmerNote: farmerNote.toString(),
                          status: status.toString(),
                          aiStatus: aiStatus.toString(),
                          possibleProblem: displayProblemName,
                          severity: severity,
                          urgency: urgency,
                          imageQuality: imageQuality,
                          severityColor: _severityColor(
                            severityEnglish.toString(),
                          ),
                          urgencyColor: _urgencyColor(
                            urgencyEnglish.toString(),
                          ),
                          imageQualityColor: _imageQualityColor(
                            imageQualityEnglish.toString(),
                          ),
                          expertVerified: expertVerified == true,
                          detailData: detailData,
                        );
                      }),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard({required int totalCount, required int showingCount}) {
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
      child: Row(
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
                'Showing $showingCount of $totalCount plant reports',
                '$totalCount मध्ये $showingCount बिरुवा रिपोर्ट देखाइँदै',
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
    );
  }

  Widget _summaryDashboard({
    required int totalCount,
    required int pendingCount,
    required int reviewedCount,
    required int urgentSoonCount,
    required int seriousCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.text('My report summary', 'मेरो रिपोर्ट सारांश'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryTile(
                icon: Icons.assignment,
                label: AppLanguage.text('Total', 'कुल'),
                count: totalCount,
                color: Colors.green,
                filterValue: 'all',
              ),
              _summaryTile(
                icon: Icons.pending_actions,
                label: AppLanguage.text('Pending', 'बाँकी'),
                count: pendingCount,
                color: Colors.orange,
                filterValue: 'pending',
              ),
              _summaryTile(
                icon: Icons.verified,
                label: AppLanguage.text('Reviewed', 'समीक्षा'),
                count: reviewedCount,
                color: Colors.green,
                filterValue: 'reviewed',
              ),
              _summaryTile(
                icon: Icons.warning_amber,
                label: AppLanguage.text('Urgent', 'जरुरी'),
                count: urgentSoonCount,
                color: Colors.red,
                filterValue: 'urgent',
              ),
              _summaryTile(
                icon: Icons.priority_high,
                label: AppLanguage.text('Serious', 'गम्भीर'),
                count: seriousCount,
                color: Colors.deepOrange,
                filterValue: 'serious',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required String filterValue,
  }) {
    final selected = _selectedFilter == filterValue;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.16) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withOpacity(0.45) : color.withOpacity(0.18),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard({
    required BuildContext context,
    required String docId,
    required String farmerNote,
    required String status,
    required String aiStatus,
    required String possibleProblem,
    required String severity,
    required String urgency,
    required String imageQuality,
    required Color severityColor,
    required Color urgencyColor,
    required Color imageQualityColor,
    required bool expertVerified,
    required Map<String, dynamic> detailData,
  }) {
    final statusColor = _statusColor(status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropReportDetailScreen(data: detailData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(Icons.eco, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLanguage.text(
                      'Plant Problem Report',
                      'बिरुवा समस्या रिपोर्ट',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteReport(context, docId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _smallInfoBox(
              icon: Icons.edit_note,
              title: AppLanguage.text('Your note', 'तपाईंको नोट'),
              text: farmerNote.trim().isEmpty
                  ? AppLanguage.text('No note added', 'नोट थपिएको छैन')
                  : _translateFarmerNote(farmerNote),
              color: Colors.blue,
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statusChip(_formatStatus(status), statusColor),
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

            if (possibleProblem.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _smallInfoBox(
                icon: Icons.bug_report,
                title: AppLanguage.text('Possible problem', 'सम्भावित समस्या'),
                text: possibleProblem,
                color: Colors.green,
              ),
            ],

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppLanguage.text(
                    'Tap to view details',
                    'विवरण हेर्न थिच्नुहोस्',
                  ),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: Colors.green.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfoBox({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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

  Widget _filteredEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.filter_alt_off, color: Colors.green, size: 50),
          const SizedBox(height: 12),
          Text(
            AppLanguage.text(
              'No reports found for this section',
              'यो भागमा कुनै रिपोर्ट भेटिएन',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Tap Total to see all reports again.',
              'सबै रिपोर्ट हेर्न Total थिच्नुहोस्।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 58,
                color: Colors.green,
              ),
              const SizedBox(height: 14),
              Text(
                AppLanguage.text(
                  'No plant reports yet',
                  'अहिले सम्म कुनै बिरुवा रिपोर्ट छैन',
                ),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLanguage.text(
                  'Submit a plant photo from Crop Check page.',
                  'बाली जाँच पेजबाट बिरुवाको फोटो पेश गर्नुहोस्।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
