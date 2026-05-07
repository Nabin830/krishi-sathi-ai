import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';
import 'admin_report_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'all';
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _reportsStream() {
    return FirebaseFirestore.instance
        .collection('cropReports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatStatus(String status) {
    if (status == 'pending_review') {
      return AppLanguage.text('Waiting for Review', 'समीक्षाको प्रतीक्षामा');
    }

    if (status == 'reviewed') {
      return AppLanguage.text('Expert Reviewed', 'विशेषज्ञद्वारा समीक्षा भएको');
    }

    if (status == 'solved') {
      return AppLanguage.text('Solved', 'समाधान भयो');
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

  Color _statusColor(String status) {
    if (status == 'reviewed') return Colors.green;
    if (status == 'solved') return Colors.blueGrey;
    return Colors.orange;
  }

  IconData _statusIcon(String status) {
    if (status == 'reviewed') return Icons.verified;
    if (status == 'solved') return Icons.check_circle;
    return Icons.pending_actions;
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

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return AppLanguage.text('Date not available', 'मिति उपलब्ध छैन');
    }

    final date = value.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
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

    if (_selectedFilter == 'solved') {
      return status == 'solved';
    }

    if (_selectedFilter == 'urgent') {
      return urgency == 'urgent' || urgency == 'soon';
    }

    if (_selectedFilter == 'high') {
      return severity == 'high' || severity == 'medium';
    }

    return true;
  }

  bool _passesSearch(Map<String, dynamic> data) {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) return true;

    final farmerNote = (data['farmerNote'] ?? data['description'] ?? '')
        .toString()
        .toLowerCase();
    final userEmail = (data['userEmail'] ?? '').toString().toLowerCase();
    final status = (data['status'] ?? '').toString().toLowerCase();
    final aiStatus = (data['aiStatus'] ?? '').toString().toLowerCase();
    final problem = (data['aiProblemName'] ?? '').toString().toLowerCase();
    final problemNe = (data['aiProblemNameNe'] ?? '').toString().toLowerCase();
    final severity = (data['aiSeverity'] ?? '').toString().toLowerCase();
    final urgency = (data['aiUrgency'] ?? '').toString().toLowerCase();

    return farmerNote.contains(query) ||
        userEmail.contains(query) ||
        status.contains(query) ||
        aiStatus.contains(query) ||
        problem.contains(query) ||
        problemNe.contains(query) ||
        severity.contains(query) ||
        urgency.contains(query);
  }

  void _sortReports(List<QueryDocumentSnapshot<Map<String, dynamic>>> reports) {
    if (_selectedFilter == 'urgent') {
      reports.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();

        final rankA = _urgencyRank((dataA['aiUrgency'] ?? '').toString());
        final rankB = _urgencyRank((dataB['aiUrgency'] ?? '').toString());

        return rankB.compareTo(rankA);
      });
      return;
    }

    if (_selectedFilter == 'high') {
      reports.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();

        final rankA = _severityRank((dataA['aiSeverity'] ?? '').toString());
        final rankB = _severityRank((dataB['aiSeverity'] ?? '').toString());

        return rankB.compareTo(rankA);
      });
    }
  }

  int _countPending(List<QueryDocumentSnapshot<Map<String, dynamic>>> reports) {
    return reports.where((doc) {
      final data = doc.data();
      return (data['status'] ?? '').toString() == 'pending_review';
    }).length;
  }

  int _countReviewed(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reports,
  ) {
    return reports.where((doc) {
      final data = doc.data();
      return (data['status'] ?? '').toString() == 'reviewed';
    }).length;
  }

  int _countSolved(List<QueryDocumentSnapshot<Map<String, dynamic>>> reports) {
    return reports.where((doc) {
      final data = doc.data();
      return (data['status'] ?? '').toString() == 'solved';
    }).length;
  }

  int _countUrgentOrSoon(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reports,
  ) {
    return reports.where((doc) {
      final data = doc.data();
      final urgency = (data['aiUrgency'] ?? '').toString().toLowerCase();
      return urgency == 'urgent' || urgency == 'soon';
    }).length;
  }

  int _countHighOrMedium(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reports,
  ) {
    return reports.where((doc) {
      final data = doc.data();
      final severity = (data['aiSeverity'] ?? '').toString().toLowerCase();
      return severity == 'high' || severity == 'medium';
    }).length;
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('cropReports')
        .doc(docId)
        .update({
          'status': status,
          'expertVerified': status == 'reviewed' || status == 'solved',
          'updatedAt': FieldValue.serverTimestamp(),
        });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text('Report status updated', 'रिपोर्ट स्थिति अपडेट भयो'),
        ),
      ),
    );
  }

  void _openQuickActionSheet({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final currentStatus = (data['status'] ?? 'pending_review').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4F8F3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLanguage.text(
                    'Admin Report Action',
                    'एडमिन रिपोर्ट कार्य',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppLanguage.text('Current status', 'हालको स्थिति')}: ${_formatStatus(currentStatus)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                _sheetButton(
                  icon: Icons.pending_actions,
                  text: AppLanguage.text(
                    'Mark as Pending',
                    'समीक्षा बाँकी बनाउनुहोस्',
                  ),
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(docId, 'pending_review');
                  },
                ),
                _sheetButton(
                  icon: Icons.verified,
                  text: AppLanguage.text(
                    'Mark as Reviewed',
                    'समीक्षा भएको बनाउनुहोस्',
                  ),
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(docId, 'reviewed');
                  },
                ),
                _sheetButton(
                  icon: Icons.check_circle,
                  text: AppLanguage.text(
                    'Mark as Solved',
                    'समाधान भयो बनाउनुहोस्',
                  ),
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(docId, 'solved');
                  },
                ),
                _sheetButton(
                  icon: Icons.open_in_new,
                  text: AppLanguage.text(
                    'Open Full Review',
                    'पूरा समीक्षा खोल्नुहोस्',
                  ),
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminReportDetailScreen(docId: docId, data: data),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.45)),
          padding: const EdgeInsets.all(13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
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
              AppLanguage.text('Admin Plant Reports', 'एडमिन बिरुवा रिपोर्ट'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _reportsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }

                final allReports = snapshot.data?.docs ?? [];

                if (allReports.isEmpty) {
                  return _emptyState();
                }

                final filteredReports = allReports.where((doc) {
                  final data = doc.data();
                  return _passesFilter(data) && _passesSearch(data);
                }).toList();

                _sortReports(filteredReports);

                final totalCount = allReports.length;
                final pendingCount = _countPending(allReports);
                final reviewedCount = _countReviewed(allReports);
                final solvedCount = _countSolved(allReports);
                final urgentSoonCount = _countUrgentOrSoon(allReports);
                final highMediumCount = _countHighOrMedium(allReports);

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
                      solvedCount: solvedCount,
                      urgentSoonCount: urgentSoonCount,
                      highMediumCount: highMediumCount,
                    ),
                    const SizedBox(height: 14),
                    _searchCard(),
                    const SizedBox(height: 14),
                    _filterBar(),
                    const SizedBox(height: 18),
                    if (filteredReports.isEmpty)
                      _filteredEmptyState()
                    else
                      ...filteredReports.map((doc) {
                        final data = doc.data();

                        final farmerNote =
                            data['farmerNote'] ??
                            data['description'] ??
                            AppLanguage.text('No note added', 'नोट थपिएको छैन');

                        final userEmail = data['userEmail'] ?? 'No email';
                        final status = data['status'] ?? 'pending_review';
                        final aiStatus = data['aiStatus'] ?? 'not_processed';
                        final expertVerified = data['expertVerified'] ?? false;

                        final problemName = _displayText(
                          (data['aiProblemName'] ?? '').toString(),
                          (data['aiProblemNameNe'] ?? '').toString(),
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

                        final severityEnglish = (data['aiSeverity'] ?? '')
                            .toString();
                        final urgencyEnglish = (data['aiUrgency'] ?? '')
                            .toString();
                        final imageQualityEnglish =
                            (data['aiImageQuality'] ?? '').toString();

                        return _reportCard(
                          context: context,
                          docId: doc.id,
                          data: data,
                          farmerNote: farmerNote.toString(),
                          userEmail: userEmail.toString(),
                          status: status.toString(),
                          aiStatus: aiStatus.toString(),
                          possibleProblem: problemName,
                          severity: severity,
                          urgency: urgency,
                          imageQuality: imageQuality,
                          severityColor: _severityColor(severityEnglish),
                          urgencyColor: _urgencyColor(urgencyEnglish),
                          imageQualityColor: _imageQualityColor(
                            imageQualityEnglish,
                          ),
                          expertVerified: expertVerified == true,
                        );
                      }),
                    const SizedBox(height: 24),
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
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.green,
              size: 34,
            ),
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
    required int solvedCount,
    required int urgentSoonCount,
    required int highMediumCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.text('Dashboard summary', 'ड्यासबोर्ड सारांश'),
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
                icon: Icons.check_circle,
                label: AppLanguage.text('Solved', 'समाधान'),
                count: solvedCount,
                color: Colors.blueGrey,
                filterValue: 'solved',
              ),
              _summaryTile(
                icon: Icons.warning_amber,
                label: AppLanguage.text('Urgent/Soon', 'जरुरी'),
                count: urgentSoonCount,
                color: Colors.red,
                filterValue: 'urgent',
              ),
              _summaryTile(
                icon: Icons.priority_high,
                label: AppLanguage.text('High/Medium', 'गम्भीर'),
                count: highMediumCount,
                color: Colors.deepOrange,
                filterValue: 'high',
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
        width: 145,
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
                    maxLines: 1,
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

  Widget _searchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: AppLanguage.text(
            'Search farmer, problem, note or status',
            'किसान, समस्या, नोट वा स्थिति खोज्नुहोस्',
          ),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLanguage.text('Filter reports', 'रिपोर्ट छान्नुहोस्'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(
                value: 'all',
                label: AppLanguage.text('All', 'सबै'),
                icon: Icons.list,
              ),
              _filterChip(
                value: 'pending',
                label: AppLanguage.text('Pending', 'समीक्षा बाँकी'),
                icon: Icons.pending_actions,
              ),
              _filterChip(
                value: 'reviewed',
                label: AppLanguage.text('Reviewed', 'समीक्षा भएको'),
                icon: Icons.verified,
              ),
              _filterChip(
                value: 'solved',
                label: AppLanguage.text('Solved', 'समाधान'),
                icon: Icons.check_circle,
              ),
              _filterChip(
                value: 'urgent',
                label: AppLanguage.text('Urgent/Soon', 'जरुरी/चाँडै'),
                icon: Icons.warning_amber,
              ),
              _filterChip(
                value: 'high',
                label: AppLanguage.text('High/Medium', 'उच्च/मध्यम'),
                icon: Icons.priority_high,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _selectedFilter == value;

    return ChoiceChip(
      selected: selected,
      avatar: Icon(
        icon,
        size: 17,
        color: selected ? Colors.white : Colors.green.shade700,
      ),
      label: Text(label),
      selectedColor: Colors.green.shade700,
      backgroundColor: Colors.green.shade50,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.green.shade800,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _reportCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
    required String farmerNote,
    required String userEmail,
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
  }) {
    final statusColor = _statusColor(status);
    final createdAt = _formatDate(data['createdAt']);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AdminReportDetailScreen(docId: docId, data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(borderColor: statusColor.withOpacity(0.16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(_statusIcon(status), color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLanguage.text(
                      'Plant Problem Report',
                      'बिरुवा समस्या रिपोर्ट',
                    ),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _openQuickActionSheet(docId: docId, data: data),
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _smallInfoBox(
              icon: Icons.email,
              title: AppLanguage.text('Farmer', 'किसान'),
              text: userEmail,
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            _smallInfoBox(
              icon: Icons.edit_note,
              title: AppLanguage.text('Farmer note', 'किसानको नोट'),
              text: farmerNote.trim().isEmpty
                  ? AppLanguage.text('No note added', 'नोट थपिएको छैन')
                  : _translateFarmerNote(farmerNote),
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            _smallInfoBox(
              icon: Icons.schedule,
              title: AppLanguage.text('Submitted', 'पेश गरिएको'),
              text: createdAt,
              color: Colors.teal,
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
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openQuickActionSheet(docId: docId, data: data),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: Text(AppLanguage.text('Quick Action', 'छिटो कार्य')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: statusColor,
                      side: BorderSide(color: statusColor.withOpacity(0.45)),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminReportDetailScreen(docId: docId, data: data),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: Text(AppLanguage.text('Review', 'समीक्षा')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
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
        border: Border.all(color: color.withOpacity(0.16)),
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
            AppLanguage.text('No reports found', 'कुनै रिपोर्ट भेटिएन'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Try another search or filter.',
              'अर्को खोज वा फिल्टर प्रयास गर्नुहोस्।',
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
                  'Farmer crop reports will appear here.',
                  'किसानका बाली रिपोर्टहरू यहाँ देखिनेछन्।',
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

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.withOpacity(0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: borderColor == null ? null : Border.all(color: borderColor),
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
