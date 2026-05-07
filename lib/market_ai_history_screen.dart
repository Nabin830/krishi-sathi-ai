import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_language.dart';

class MarketAiHistoryScreen extends StatelessWidget {
  const MarketAiHistoryScreen({super.key});

  String _text(String en, String ne) {
    return AppLanguage.text(en, ne);
  }

  String _displayText(String english, String nepali) {
    if (AppLanguage.isNepali && nepali.trim().isNotEmpty) {
      return nepali;
    }

    return english;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('marketAiHistory')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatPrice(dynamic price, String unit) {
    final value = _toDouble(price);

    if (value == value.roundToDouble()) {
      return 'Rs. ${value.round()}/$unit';
    }

    return 'Rs. ${value.toStringAsFixed(2)}/$unit';
  }

  Color _riskColor(String risk, String trend) {
    final cleanRisk = risk.toLowerCase();
    final cleanTrend = trend.toLowerCase();

    if (cleanRisk.contains('good') ||
        cleanRisk.contains('opportunity') ||
        cleanRisk.contains('राम्रो') ||
        cleanRisk.contains('अवसर') ||
        cleanTrend.contains('high')) {
      return Colors.green;
    }

    if (cleanRisk.contains('low') ||
        cleanRisk.contains('warning') ||
        cleanRisk.contains('कम') ||
        cleanRisk.contains('चेतावनी') ||
        cleanTrend.contains('low')) {
      return Colors.red;
    }

    return Colors.orange;
  }

  IconData _riskIcon(String risk, String trend) {
    final cleanRisk = risk.toLowerCase();
    final cleanTrend = trend.toLowerCase();

    if (cleanRisk.contains('good') ||
        cleanRisk.contains('opportunity') ||
        cleanRisk.contains('राम्रो') ||
        cleanRisk.contains('अवसर') ||
        cleanTrend.contains('high')) {
      return Icons.trending_up;
    }

    if (cleanRisk.contains('low') ||
        cleanRisk.contains('warning') ||
        cleanRisk.contains('कम') ||
        cleanRisk.contains('चेतावनी') ||
        cleanTrend.contains('low')) {
      return Icons.trending_down;
    }

    return Icons.trending_flat;
  }

  String _trendNe(String trend) {
    if (trend == 'High demand') return 'धेरै माग';
    if (trend == 'Low price') return 'कम मूल्य';
    return 'स्थिर';
  }

  Future<void> _deleteHistory(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_text('Delete selling advice?', 'बिक्री सुझाव हटाउने?')),
          content: Text(
            _text(
              'This saved AI market advice will be removed.',
              'यो सेभ गरिएको एआई बजार सुझाव हटाइनेछ।',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_text('Cancel', 'रद्द गर्नुहोस्')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(_text('Delete', 'हटाउनुहोस्')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('marketAiHistory')
        .doc(docId)
        .delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_text('Market advice deleted', 'बजार सुझाव हटाइयो')),
      ),
    );
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
              _text('Market AI History', 'बजार एआई इतिहास'),
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
                    title: _text(
                      'Please login first',
                      'कृपया पहिले लगइन गर्नुहोस्',
                    ),
                    subtitle: _text(
                      'Market AI history is available after login.',
                      'बजार एआई इतिहास लगइन गरेपछि उपलब्ध हुन्छ।',
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

                if (docs.isEmpty) {
                  return _emptyState(
                    icon: Icons.history,
                    title: _text(
                      'No saved market advice yet',
                      'अहिलेसम्म कुनै सेभ बजार सुझाव छैन',
                    ),
                    subtitle: _text(
                      'Open Prices and tap Get AI Selling Advice.',
                      'Prices खोलेर Get AI Selling Advice थिच्नुहोस्।',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(docs.length),
                    const SizedBox(height: 16),
                    ...docs.map((doc) {
                      return _historyCard(
                        context: context,
                        docId: doc.id,
                        data: doc.data(),
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

  Widget _headerCard(int count) {
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
            child: Icon(Icons.auto_awesome, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _text(
                '$count saved AI selling advice',
                '$count सेभ गरिएको एआई बिक्री सुझाव',
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

  Widget _historyCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final cropName = _displayText(
      (data['cropName'] ?? '').toString(),
      (data['cropNameNe'] ?? '').toString(),
    );

    final marketName = (data['marketName'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final unit = (data['unit'] ?? 'kg').toString();
    final trend = (data['trend'] ?? 'Stable').toString();
    final note = (data['note'] ?? '').toString();

    final priceText = _formatPrice(data['price'], unit);

    final risk = _displayText(
      (data['aiMarketRisk'] ?? '').toString(),
      (data['aiMarketRiskNe'] ?? '').toString(),
    );

    final title = _displayText(
      (data['aiMarketTitle'] ?? '').toString(),
      (data['aiMarketTitleNe'] ?? '').toString(),
    );

    final summary = _displayText(
      (data['aiMarketSummary'] ?? '').toString(),
      (data['aiMarketSummaryNe'] ?? '').toString(),
    );

    final actions = AppLanguage.isNepali
        ? _toStringList(data['aiMarketActionsNe'])
        : _toStringList(data['aiMarketActions']);

    final createdAt = _formatDate(data['createdAt']);

    final color = _riskColor(risk, trend);
    final icon = _riskIcon(risk, trend);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        color: Colors.white,
        borderColor: color.withOpacity(0.16),
      ),
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
                      ? _text('Crop Selling Advice', 'बाली बिक्री सुझाव')
                      : cropName,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _deleteHistory(context, docId),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _smallLine(icon: Icons.payments, text: priceText),
          if (marketName.trim().isNotEmpty)
            _smallLine(icon: Icons.store, text: marketName),
          if (location.trim().isNotEmpty)
            _smallLine(icon: Icons.place, text: location),
          if (createdAt.trim().isNotEmpty)
            _smallLine(icon: Icons.schedule, text: createdAt),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                label: risk.trim().isEmpty
                    ? _text('Market Advice', 'बजार सुझाव')
                    : risk,
                color: color,
              ),
              _chip(label: _text(trend, _trendNe(trend)), color: Colors.green),
              _chip(
                label: _text('Unit: $unit', 'एकाइ: $unit'),
                color: Colors.teal,
              ),
            ],
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (title.trim().isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _text('What farmer can do', 'किसानले के गर्न सक्छ'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            ...actions
                .take(3)
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            action,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Text(
            _text(
              'This advice is only guidance. Compare real market prices before selling.',
              'यो सुझाव केवल मार्गदर्शन हो। बेच्नु अघि वास्तविक बजार मूल्य तुलना गर्नुहोस्।',
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

  Widget _smallLine({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.black45, size: 17),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
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
