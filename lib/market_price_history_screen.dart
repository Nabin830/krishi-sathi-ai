import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_language.dart';

class MarketPriceHistoryScreen extends StatefulWidget {
  const MarketPriceHistoryScreen({super.key});

  @override
  State<MarketPriceHistoryScreen> createState() =>
      _MarketPriceHistoryScreenState();
}

class _MarketPriceHistoryScreenState extends State<MarketPriceHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _priceHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('marketPrices')
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

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    final cleanValue = value
        .toString()
        .replaceAll('Rs.', '')
        .replaceAll('रु.', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();

    return double.tryParse(cleanValue) ?? 0;
  }

  String _formatPrice(dynamic price, String unit) {
    final value = _toDouble(price);

    if (value == value.roundToDouble()) {
      return 'Rs. ${value.round()}/$unit';
    }

    return 'Rs. ${value.toStringAsFixed(2)}/$unit';
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

  Color _trendColor(String trend) {
    final value = trend.toLowerCase();

    if (value.contains('high')) return Colors.orange;
    if (value.contains('low')) return Colors.blue;
    if (value.contains('fall')) return Colors.red;
    if (value.contains('rise')) return Colors.orange;
    if (value.contains('stable')) return Colors.green;

    return Colors.teal;
  }

  IconData _trendIcon(String trend) {
    final value = trend.toLowerCase();

    if (value.contains('high')) return Icons.trending_up;
    if (value.contains('low')) return Icons.trending_down;
    if (value.contains('fall')) return Icons.trending_down;
    if (value.contains('rise')) return Icons.trending_up;
    if (value.contains('stable')) return Icons.trending_flat;

    return Icons.store;
  }

  String _trendText(String trend) {
    final value = trend.toLowerCase();

    if (value.contains('high')) {
      return AppLanguage.text('High demand', 'धेरै माग');
    }

    if (value.contains('low')) {
      return AppLanguage.text('Low demand', 'कम माग');
    }

    if (value.contains('fall')) {
      return AppLanguage.text('Price falling', 'मूल्य घट्दै');
    }

    if (value.contains('rise')) {
      return AppLanguage.text('Price rising', 'मूल्य बढ्दै');
    }

    if (value.contains('stable')) {
      return AppLanguage.text('Stable', 'स्थिर');
    }

    return AppLanguage.text('Market price', 'बजार मूल्य');
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data();

      final crop = (data['cropName'] ?? '').toString().toLowerCase();
      final cropNe = (data['cropNameNe'] ?? '').toString().toLowerCase();
      final market = (data['marketName'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      final trend = (data['trend'] ?? '').toString().toLowerCase();

      return crop.contains(query) ||
          cropNe.contains(query) ||
          market.contains(query) ||
          location.contains(query) ||
          trend.contains(query);
    }).toList();
  }

  Future<void> _deletePrice(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLanguage.text('Delete price record?', 'मूल्य रेकर्ड हटाउने?'),
          ),
          content: Text(
            AppLanguage.text(
              'This market price history record will be deleted.',
              'यो बजार मूल्य इतिहास रेकर्ड हटाइनेछ।',
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
          .collection('marketPrices')
          .doc(docId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text('Price record deleted', 'मूल्य रेकर्ड हटाइयो'),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              'Failed to delete price: $e',
              'मूल्य हटाउन समस्या भयो: $e',
            ),
          ),
        ),
      );
    }
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
              AppLanguage.text('Market Price History', 'बजार मूल्य इतिहास'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _priceHistoryStream(),
              builder: (context, snapshot) {
                if (FirebaseAuth.instance.currentUser == null) {
                  return _emptyState(
                    icon: Icons.lock,
                    title: AppLanguage.text(
                      'Please login first',
                      'कृपया पहिले लगइन गर्नुहोस्',
                    ),
                    subtitle: AppLanguage.text(
                      'Your market price history will appear after login.',
                      'लगइन गरेपछि तपाईंको बजार मूल्य इतिहास देखिनेछ।',
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
                      'No market price history yet',
                      'अहिलेसम्म बजार मूल्य इतिहास छैन',
                    ),
                    subtitle: AppLanguage.text(
                      'Open Prices and add a local market price first.',
                      'Prices खोलेर पहिले स्थानीय बजार मूल्य थप्नुहोस्।',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(docs.length),
                    const SizedBox(height: 16),
                    _searchCard(),
                    const SizedBox(height: 16),
                    if (filteredDocs.isEmpty)
                      _emptySearchCard()
                    else
                      ...filteredDocs.map((doc) {
                        return _priceHistoryCard(
                          context: context,
                          docId: doc.id,
                          data: doc.data(),
                        );
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
            child: Icon(Icons.history, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLanguage.text(
                '$count saved market price records',
                '$count सेभ गरिएको बजार मूल्य रेकर्ड',
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
            'Search crop, market, location or trend',
            'बाली, बजार, स्थान वा अवस्था खोज्नुहोस्',
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

  Widget _priceHistoryCard({
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
    final trend = (data['trend'] ?? 'stable').toString();
    final note = (data['note'] ?? '').toString();

    final priceText = _formatPrice(data['priceValue'] ?? data['price'], unit);
    final dateText = _formatDate(data['createdAt']);

    final color = _trendColor(trend);
    final icon = _trendIcon(trend);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: color.withOpacity(0.16)),
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
                      ? AppLanguage.text('Crop Price', 'बाली मूल्य')
                      : cropName,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _deletePrice(context, docId),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bigPriceBox(priceText, color),
          const SizedBox(height: 12),
          _smallLine(
            icon: Icons.store,
            text: marketName.trim().isEmpty
                ? AppLanguage.text('Market not added', 'बजार थपिएको छैन')
                : marketName,
          ),
          _smallLine(
            icon: Icons.place,
            text: location.trim().isEmpty
                ? AppLanguage.text('Location not added', 'स्थान थपिएको छैन')
                : location,
          ),
          _smallLine(icon: Icons.schedule, text: dateText),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(label: _trendText(trend), color: color),
              _chip(
                label: AppLanguage.text('Unit: $unit', 'एकाइ: $unit'),
                color: Colors.teal,
              ),
            ],
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withOpacity(0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bigPriceBox(String price, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.payments, color: color),
          const SizedBox(width: 8),
          Text(
            AppLanguage.text('Price', 'मूल्य'),
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              price,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLine({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.black45, size: 17),
          const SizedBox(width: 6),
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
              'No matching price record',
              'मिल्ने मूल्य रेकर्ड भेटिएन',
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Try another crop, market or location name.',
              'अर्को बाली, बजार वा स्थानको नाम खोज्नुहोस्।',
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
