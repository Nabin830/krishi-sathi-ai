import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';

class BuyerMarketScreen extends StatefulWidget {
  const BuyerMarketScreen({super.key});

  @override
  State<BuyerMarketScreen> createState() => _BuyerMarketScreenState();
}

class _BuyerMarketScreenState extends State<BuyerMarketScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _listingsStream() {
    return FirebaseFirestore.instance
        .collection('cropListings')
        .where('status', isEqualTo: 'active')
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

  DateTime _readCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _safeQuantity(Map<String, dynamic> data) {
    final oldQuantity = (data['quantity'] ?? '').toString();

    if (oldQuantity.trim().isNotEmpty) return oldQuantity;

    final value = data['quantityValue'];
    final unit = (data['quantityUnit'] ?? 'kg').toString();

    if (value == null) {
      return AppLanguage.text('Quantity not added', 'मात्रा थपिएको छैन');
    }

    return '$value $unit';
  }

  String _safePrice(Map<String, dynamic> data) {
    final oldPrice = (data['price'] ?? '').toString();

    if (oldPrice.trim().isNotEmpty) return oldPrice;

    final value = data['priceValue'];
    final unit = (data['priceUnit'] ?? 'kg').toString();

    if (value == null) {
      return AppLanguage.text('Price not added', 'मूल्य थपिएको छैन');
    }

    return 'Rs. $value/$unit';
  }

  Color _qualityColor(String quality) {
    if (quality == 'Excellent') return Colors.green;
    if (quality == 'Average') return Colors.orange;
    return Colors.teal;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sortedDocs = [...docs];

    sortedDocs.sort((a, b) {
      final aDate = _readCreatedAt(a.data());
      final bDate = _readCreatedAt(b.data());

      return bDate.compareTo(aDate);
    });

    return sortedDocs;
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
      final location = (data['location'] ?? '').toString().toLowerCase();
      final quality = (data['quality'] ?? '').toString().toLowerCase();
      final note = (data['note'] ?? '').toString().toLowerCase();

      return crop.contains(query) ||
          cropNe.contains(query) ||
          location.contains(query) ||
          quality.contains(query) ||
          note.contains(query);
    }).toList();
  }

  void _showContactSheet(Map<String, dynamic> data) {
    final cropName = _displayText(
      (data['cropName'] ?? '').toString(),
      (data['cropNameNe'] ?? '').toString(),
    );

    final contact = (data['contact'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final sellerEmail = (data['userEmail'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4F8F3),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(Icons.phone, color: Colors.green.shade700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLanguage.text(
                            'Seller Contact',
                            'बिक्रेता सम्पर्क',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _cropImage(imageUrl),
                  const SizedBox(height: 16),
                  _detailLine(
                    icon: Icons.eco,
                    label: AppLanguage.text('Crop', 'बाली'),
                    value: cropName.trim().isEmpty
                        ? AppLanguage.text('Crop', 'बाली')
                        : cropName,
                  ),
                  _detailLine(
                    icon: Icons.place,
                    label: AppLanguage.text('Location', 'स्थान'),
                    value: location.trim().isEmpty
                        ? AppLanguage.text(
                            'Location not added',
                            'स्थान थपिएको छैन',
                          )
                        : location,
                  ),
                  _detailLine(
                    icon: Icons.phone,
                    label: AppLanguage.text('Contact', 'सम्पर्क'),
                    value: contact.trim().isEmpty
                        ? AppLanguage.text(
                            'Contact not added',
                            'सम्पर्क थपिएको छैन',
                          )
                        : contact,
                  ),
                  if (sellerEmail.trim().isNotEmpty)
                    _detailLine(
                      icon: Icons.email,
                      label: AppLanguage.text('Email', 'इमेल'),
                      value: sellerEmail,
                    ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLanguage.text(
                              'Please confirm crop quality, quantity, price and pickup details directly with the seller.',
                              'कृपया बालीको गुणस्तर, मात्रा, मूल्य र लिन जाने विवरण बिक्रेतासँग सिधै पुष्टि गर्नुहोस्।',
                            ),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
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
              AppLanguage.text('Marketplace', 'बजार'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _listingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }

                final docs = _sortDocs(snapshot.data?.docs ?? []);
                final filteredDocs = _filterDocs(docs);

                if (docs.isEmpty) {
                  return _emptyState(
                    icon: Icons.shopping_cart,
                    title: AppLanguage.text(
                      'No active crop listings',
                      'अहिले active बाली लिस्टिङ छैन',
                    ),
                    subtitle: AppLanguage.text(
                      'Listings created by farmers will appear here.',
                      'किसानले बनाएको लिस्टिङ यहाँ देखिनेछ।',
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
                        return _listingCard(doc.data());
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
            child: Icon(Icons.shopping_cart, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLanguage.text(
                '$count active crop listings',
                '$count active बाली लिस्टिङ',
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
            'Search crop, location or quality',
            'बाली, स्थान वा गुणस्तर खोज्नुहोस्',
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

  Widget _listingCard(Map<String, dynamic> data) {
    final cropName = _displayText(
      (data['cropName'] ?? '').toString(),
      (data['cropNameNe'] ?? '').toString(),
    );

    final quantity = _safeQuantity(data);
    final price = _safePrice(data);
    final location = (data['location'] ?? '').toString();
    final contact = (data['contact'] ?? '').toString();
    final note = (data['note'] ?? '').toString();
    final quality = (data['quality'] ?? 'Good').toString();
    final qualityNe = (data['qualityNe'] ?? '').toString();
    final createdAt = _formatDate(data['createdAt']);
    final imageUrl = (data['imageUrl'] ?? '').toString();

    final color = _qualityColor(quality);

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
                backgroundColor: color.withOpacity(0.13),
                child: Icon(Icons.eco, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cropName.trim().isEmpty
                      ? AppLanguage.text('Crop Listing', 'बाली लिस्टिङ')
                      : cropName,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.14)),
                ),
                child: Text(
                  AppLanguage.text(
                    quality,
                    qualityNe.isEmpty ? quality : qualityNe,
                  ),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _cropImage(imageUrl),
          const SizedBox(height: 12),
          _priceBox(price, color),
          const SizedBox(height: 12),
          _detailLine(
            icon: Icons.scale,
            label: AppLanguage.text('Quantity', 'मात्रा'),
            value: quantity,
          ),
          _detailLine(
            icon: Icons.place,
            label: AppLanguage.text('Location', 'स्थान'),
            value: location.trim().isEmpty
                ? AppLanguage.text('Location not added', 'स्थान थपिएको छैन')
                : location,
          ),
          _detailLine(
            icon: Icons.phone,
            label: AppLanguage.text('Contact', 'सम्पर्क'),
            value: contact.trim().isEmpty
                ? AppLanguage.text('Contact not added', 'सम्पर्क थपिएको छैन')
                : contact,
          ),
          _detailLine(
            icon: Icons.schedule,
            label: AppLanguage.text('Posted', 'पोस्ट गरिएको'),
            value: createdAt,
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showContactSheet(data),
              icon: const Icon(Icons.phone),
              label: Text(
                AppLanguage.text(
                  'Contact Seller',
                  'बिक्रेतालाई सम्पर्क गर्नुहोस्',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(13),
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

  Widget _cropImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        width: double.infinity,
        height: 165,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.green.shade700,
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              AppLanguage.text('No crop photo', 'बालीको फोटो छैन'),
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: double.infinity,
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 165,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.20)),
            ),
            child: Text(
              AppLanguage.text('Photo failed to load', 'फोटो लोड हुन सकेन'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _priceBox(String price, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.14)),
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
                fontSize: 17,
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
            AppLanguage.text('No matching listing', 'मिल्ने लिस्टिङ भेटिएन'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Try another crop or location.',
              'अर्को बाली वा स्थान खोज्नुहोस्।',
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
