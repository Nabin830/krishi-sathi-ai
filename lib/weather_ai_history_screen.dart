import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_language.dart';

class WeatherAiHistoryScreen extends StatefulWidget {
  const WeatherAiHistoryScreen({super.key});

  @override
  State<WeatherAiHistoryScreen> createState() => _WeatherAiHistoryScreenState();
}

class _WeatherAiHistoryScreenState extends State<WeatherAiHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('weatherAiHistory')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _displayText(String english, String nepali) {
    if (AppLanguage.isNepali && nepali.trim().isNotEmpty) {
      return nepali;
    }

    return english;
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

  List<String> _toStringList(dynamic value) {
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

  Color _riskColor(String risk) {
    final lowerRisk = risk.toLowerCase();

    if (lowerRisk.contains('high') ||
        lowerRisk.contains('risk') ||
        lowerRisk.contains('rain') ||
        lowerRisk.contains('disease')) {
      return Colors.red;
    }

    if (lowerRisk.contains('medium') ||
        lowerRisk.contains('heat') ||
        lowerRisk.contains('wind') ||
        lowerRisk.contains('cold')) {
      return Colors.orange;
    }

    return Colors.green;
  }

  IconData _riskIcon(String risk) {
    final lowerRisk = risk.toLowerCase();

    if (lowerRisk.contains('rain')) return Icons.water_drop;
    if (lowerRisk.contains('heat')) return Icons.wb_sunny;
    if (lowerRisk.contains('cold')) return Icons.ac_unit;
    if (lowerRisk.contains('wind')) return Icons.air;
    if (lowerRisk.contains('disease')) return Icons.bug_report;
    if (lowerRisk.contains('high') || lowerRisk.contains('risk')) {
      return Icons.warning_amber;
    }

    return Icons.check_circle;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data();

      final cropName = (data['cropName'] ?? '').toString().toLowerCase();
      final cropNameNe = (data['cropNameNe'] ?? '').toString().toLowerCase();
      final placeName = (data['placeName'] ?? '').toString().toLowerCase();
      final risk = (data['aiWeatherRisk'] ?? '').toString().toLowerCase();
      final summary = (data['aiWeatherSummary'] ?? '').toString().toLowerCase();

      return cropName.contains(query) ||
          cropNameNe.contains(query) ||
          placeName.contains(query) ||
          risk.contains(query) ||
          summary.contains(query);
    }).toList();
  }

  Future<void> _deleteHistory(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLanguage.text('Delete weather history?', 'मौसम इतिहास हटाउने?'),
          ),
          content: Text(
            AppLanguage.text(
              'This saved AI weather advice will be deleted.',
              'यो सेभ गरिएको एआई मौसम सुझाव हटाइनेछ।',
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

    await FirebaseFirestore.instance
        .collection('weatherAiHistory')
        .doc(docId)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text('Weather history deleted', 'मौसम इतिहास हटाइयो'),
        ),
      ),
    );
  }

  Future<void> _clearAllHistory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLanguage.text(
              'Clear all weather history?',
              'सबै मौसम इतिहास हटाउने?',
            ),
          ),
          content: Text(
            AppLanguage.text(
              'All your saved AI weather advice records will be deleted.',
              'तपाईंका सबै सेभ गरिएका एआई मौसम सुझाव हटाइनेछन्।',
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
              child: Text(AppLanguage.text('Clear All', 'सबै हटाउनुहोस्')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text(
            'All weather history cleared',
            'सबै मौसम इतिहास हटाइयो',
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
              AppLanguage.text('Weather History', 'मौसम इतिहास'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _historyStream(),
              builder: (context, snapshot) {
                if (FirebaseAuth.instance.currentUser == null) {
                  return _emptyState(
                    icon: Icons.lock,
                    title: AppLanguage.text(
                      'Please login first',
                      'कृपया पहिले लगइन गर्नुहोस्',
                    ),
                    subtitle: AppLanguage.text(
                      'Your saved weather advice will appear after login.',
                      'लगइन गरेपछि तपाईंको सेभ मौसम सुझाव देखिनेछ।',
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = _filterDocs(docs);

                if (docs.isEmpty) {
                  return _emptyState(
                    icon: Icons.history,
                    title: AppLanguage.text(
                      'No weather history yet',
                      'अहिलेसम्म मौसम इतिहास छैन',
                    ),
                    subtitle: AppLanguage.text(
                      'Open Weather, get AI farming summary, then it will appear here.',
                      'Weather खोलेर AI farming summary लिनुहोस्, त्यसपछि यहाँ देखिन्छ।',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(docs.length, docs),
                    const SizedBox(height: 16),
                    _searchCard(),
                    const SizedBox(height: 16),
                    if (filteredDocs.isEmpty)
                      _emptySearchCard()
                    else
                      ...filteredDocs.map((doc) {
                        return _historyCard(docId: doc.id, data: doc.data());
                      }),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard(
    int count,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
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
            child: Icon(Icons.history, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLanguage.text(
                '$count saved weather advice records',
                '$count सेभ गरिएको मौसम सुझाव',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _clearAllHistory(docs),
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'Clear all',
          ),
        ],
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
            'Search crop, place, risk or advice',
            'बाली, स्थान, जोखिम वा सुझाव खोज्नुहोस्',
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

  Widget _historyCard({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final cropName = _displayText(
      (data['cropName'] ?? '').toString(),
      (data['cropNameNe'] ?? '').toString(),
    );

    final placeName = (data['placeName'] ?? '').toString();
    final temperature = (data['temperature'] ?? '--°C').toString();
    final humidity = (data['humidity'] ?? '--%').toString();
    final rainChance = (data['rainChance'] ?? '--%').toString();
    final windSpeed = (data['windSpeed'] ?? '-- km/h').toString();
    final weatherType = _displayText(
      (data['weatherType'] ?? '').toString(),
      (data['weatherTypeNe'] ?? '').toString(),
    );

    final aiTitle = _displayText(
      (data['aiWeatherTitle'] ?? 'AI Weather Advice').toString(),
      (data['aiWeatherTitleNe'] ?? 'एआई मौसम सुझाव').toString(),
    );

    final aiSummary = _displayText(
      (data['aiWeatherSummary'] ?? '').toString(),
      (data['aiWeatherSummaryNe'] ?? '').toString(),
    );

    final risk = _displayText(
      (data['aiWeatherRisk'] ?? 'Normal').toString(),
      (data['aiWeatherRiskNe'] ?? 'सामान्य').toString(),
    );

    final rawRisk = (data['aiWeatherRisk'] ?? 'Normal').toString();
    final actions = AppLanguage.isNepali
        ? _toStringList(data['aiWeatherActionsNe'])
        : _toStringList(data['aiWeatherActions']);

    final createdAt = _formatDate(data['createdAt']);

    final color = _riskColor(rawRisk);
    final icon = _riskIcon(rawRisk);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: color.withOpacity(0.18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cropName.trim().isEmpty
                      ? AppLanguage.text(
                          'Crop Weather Advice',
                          'बाली मौसम सुझाव',
                        )
                      : cropName,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _deleteHistory(docId),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aiTitle,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _riskBox(risk, color),
          const SizedBox(height: 12),
          _detailLine(
            icon: Icons.place,
            label: AppLanguage.text('Place', 'स्थान'),
            value: placeName.trim().isEmpty
                ? AppLanguage.text('Place not added', 'स्थान थपिएको छैन')
                : placeName,
          ),
          _detailLine(
            icon: Icons.cloud,
            label: AppLanguage.text('Weather', 'मौसम'),
            value: weatherType.trim().isEmpty
                ? AppLanguage.text('Weather not added', 'मौसम थपिएको छैन')
                : weatherType,
          ),
          _detailLine(
            icon: Icons.schedule,
            label: AppLanguage.text('Saved', 'सेभ गरिएको'),
            value: createdAt,
          ),
          const SizedBox(height: 10),
          _weatherGrid(
            temperature: temperature,
            humidity: humidity,
            rainChance: rainChance,
            windSpeed: windSpeed,
            color: color,
          ),
          if (aiSummary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _summaryBox(aiSummary),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLanguage.text('Suggested actions', 'सुझाव गरिएको काम'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ...actions.take(5).map((action) {
              return _actionLine(action);
            }),
          ],
          const SizedBox(height: 8),
          Text(
            AppLanguage.text(
              'AI advice is only guidance. For serious crop problems or chemical use, ask a local agriculture expert.',
              'एआई सुझाव सामान्य मार्गदर्शन मात्र हो। गम्भीर बाली समस्या वा रसायन प्रयोगका लागि स्थानीय कृषि विशेषज्ञसँग सल्लाह लिनुहोस्।',
            ),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskBox(String risk, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: color),
          const SizedBox(width: 8),
          Text(
            AppLanguage.text('Risk', 'जोखिम'),
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              risk,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherGrid({
    required String temperature,
    required String humidity,
    required String rainChance,
    required String windSpeed,
    required Color color,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.7,
      children: [
        _weatherMiniTile(
          icon: Icons.thermostat,
          label: AppLanguage.text('Temp', 'तापक्रम'),
          value: temperature,
          color: color,
        ),
        _weatherMiniTile(
          icon: Icons.water_drop,
          label: AppLanguage.text('Rain', 'पानी'),
          value: rainChance,
          color: color,
        ),
        _weatherMiniTile(
          icon: Icons.opacity,
          label: AppLanguage.text('Humidity', 'आर्द्रता'),
          value: humidity,
          color: color,
        ),
        _weatherMiniTile(
          icon: Icons.air,
          label: AppLanguage.text('Wind', 'हावा'),
          value: windSpeed,
          color: color,
        ),
      ],
    );
  }

  Widget _weatherMiniTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionLine(String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black45, size: 17),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySearchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.green, size: 58),
          const SizedBox(height: 12),
          Text(
            AppLanguage.text(
              'No matching weather history',
              'मिल्ने मौसम इतिहास भेटिएन',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Try another crop, place or risk name.',
              'अर्को बाली, स्थान वा जोखिम नाम खोज्नुहोस्।',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: Colors.green),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
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

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: borderColor == null ? null : Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
