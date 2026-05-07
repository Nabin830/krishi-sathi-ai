import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_language.dart';

class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _statusFilter = 'all';

  final List<String> _statusOptions = ['all', 'active', 'sold', 'inactive'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _listingsStream() {
    return FirebaseFirestore.instance
        .collection('cropListings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _statusText(String status) {
    if (status == 'sold') return AppLanguage.text('Sold', 'बिक्री भयो');
    if (status == 'inactive') return AppLanguage.text('Inactive', 'निष्क्रिय');
    if (status == 'all') return AppLanguage.text('All', 'सबै');

    return AppLanguage.text('Active', 'सक्रिय');
  }

  Color _statusColor(String status) {
    if (status == 'sold') return Colors.blueGrey;
    if (status == 'inactive') return Colors.orange;
    return Colors.green;
  }

  IconData _statusIcon(String status) {
    if (status == 'sold') return Icons.check_circle;
    if (status == 'inactive') return Icons.pause_circle;
    return Icons.play_circle;
  }

  Color _qualityColor(String quality) {
    if (quality == 'Excellent') return Colors.green;
    if (quality == 'Average') return Colors.orange;
    return Colors.teal;
  }

  String _qualityText(String quality, String qualityNe) {
    if (AppLanguage.isNepali && qualityNe.trim().isNotEmpty) {
      return qualityNe;
    }

    if (quality.trim().isEmpty) {
      return AppLanguage.text('Good', 'राम्रो');
    }

    return quality;
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

  String _safeQuantity(Map<String, dynamic> data) {
    final oldQuantity = (data['quantity'] ?? '').toString();

    if (oldQuantity.trim().isNotEmpty) {
      return oldQuantity;
    }

    final value = data['quantityValue'];
    final unit = (data['quantityUnit'] ?? 'kg').toString();

    if (value == null) {
      return AppLanguage.text('Quantity not added', 'मात्रा थपिएको छैन');
    }

    return '$value $unit';
  }

  String _safePrice(Map<String, dynamic> data) {
    final oldPrice = (data['price'] ?? '').toString();

    if (oldPrice.trim().isNotEmpty) {
      return oldPrice;
    }

    final value = data['priceValue'];
    final unit = (data['priceUnit'] ?? 'kg').toString();

    if (value == null) {
      return AppLanguage.text('Price not added', 'मूल्य थपिएको छैन');
    }

    return 'Rs. $value/$unit';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _searchText.trim().toLowerCase();

    return docs.where((doc) {
      final data = doc.data();

      final status = (data['status'] ?? 'active').toString().toLowerCase();

      if (_statusFilter != 'all' && status != _statusFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      final crop = (data['cropName'] ?? '').toString().toLowerCase();
      final cropNe = (data['cropNameNe'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      final quality = (data['quality'] ?? '').toString().toLowerCase();
      final email = (data['userEmail'] ?? '').toString().toLowerCase();
      final contact = (data['contact'] ?? '').toString().toLowerCase();
      final note = (data['note'] ?? '').toString().toLowerCase();

      return crop.contains(query) ||
          cropNe.contains(query) ||
          location.contains(query) ||
          quality.contains(query) ||
          email.contains(query) ||
          contact.contains(query) ||
          note.contains(query) ||
          status.contains(query);
    }).toList();
  }

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('cropListings')
        .doc(docId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text(
            'Listing status updated',
            'लिस्टिङ स्थिति अपडेट भयो',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteListing(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLanguage.text('Delete listing?', 'लिस्टिङ हटाउने?')),
          content: Text(
            AppLanguage.text(
              'This listing will be permanently deleted from Marketplace.',
              'यो लिस्टिङ Marketplace बाट स्थायी रूपमा हटाइनेछ।',
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
        .collection('cropListings')
        .doc(docId)
        .delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLanguage.text('Listing deleted', 'लिस्टिङ हटाइयो')),
      ),
    );
  }

  void _openManageSheet({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final currentStatus = (data['status'] ?? 'active').toString();

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
                    'Admin Listing Action',
                    'एडमिन लिस्टिङ कार्य',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLanguage.text(
                    'Current status: ${_statusText(currentStatus)}',
                    'हालको स्थिति: ${_statusText(currentStatus)}',
                  ),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                _sheetButton(
                  icon: Icons.play_circle,
                  text: AppLanguage.text('Mark as Active', 'सक्रिय बनाउनुहोस्'),
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(docId, 'active');
                  },
                ),
                _sheetButton(
                  icon: Icons.check_circle,
                  text: AppLanguage.text(
                    'Mark as Sold',
                    'बिक्री भयो बनाउनुहोस्',
                  ),
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(docId, 'sold');
                  },
                ),
                _sheetButton(
                  icon: Icons.pause_circle,
                  text: AppLanguage.text(
                    'Mark as Inactive',
                    'निष्क्रिय बनाउनुहोस्',
                  ),
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(docId, 'inactive');
                  },
                ),
                _sheetButton(
                  icon: Icons.delete_outline,
                  text: AppLanguage.text(
                    'Delete Listing',
                    'लिस्टिङ हटाउनुहोस्',
                  ),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteListing(docId);
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
              AppLanguage.text('Admin Listings', 'एडमिन लिस्टिङ'),
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

                final docs = snapshot.data?.docs ?? [];
                final filteredDocs = _filterDocs(docs);

                if (docs.isEmpty) {
                  return _emptyState(
                    icon: Icons.list_alt,
                    title: AppLanguage.text(
                      'No crop listings yet',
                      'अहिलेसम्म बाली लिस्टिङ छैन',
                    ),
                    subtitle: AppLanguage.text(
                      'Farmer crop listings will appear here.',
                      'किसानका बाली लिस्टिङ यहाँ देखिनेछन्।',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(docs.length),
                    const SizedBox(height: 16),
                    _searchCard(),
                    const SizedBox(height: 12),
                    _filterChips(),
                    const SizedBox(height: 16),
                    if (filteredDocs.isEmpty)
                      _emptySearchCard()
                    else
                      ...filteredDocs.map((doc) {
                        return _listingCard(docId: doc.id, data: doc.data());
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

  Widget _headerCard(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade800, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.22),
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
            child: Icon(Icons.manage_search, color: Colors.orange, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLanguage.text(
                '$count total crop listings',
                '$count जम्मा बाली लिस्टिङ',
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
            'Search crop, farmer, location or status',
            'बाली, किसान, स्थान वा स्थिति खोज्नुहोस्',
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
            borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions.map((status) {
        final selected = _statusFilter == status;
        final color = status == 'all' ? Colors.orange : _statusColor(status);

        return ChoiceChip(
          selected: selected,
          label: Text(_statusText(status)),
          selectedColor: color,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide(color: color.withOpacity(0.35)),
          onSelected: (_) {
            setState(() {
              _statusFilter = status;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _listingCard({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final cropName = _displayText(
      (data['cropName'] ?? '').toString(),
      (data['cropNameNe'] ?? '').toString(),
    );

    final quantity = _safeQuantity(data);
    final price = _safePrice(data);
    final location = (data['location'] ?? '').toString();
    final contact = (data['contact'] ?? '').toString();
    final sellerEmail = (data['userEmail'] ?? '').toString();
    final note = (data['note'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final quality = (data['quality'] ?? 'Good').toString();
    final qualityNe = (data['qualityNe'] ?? '').toString();
    final status = (data['status'] ?? 'active').toString();
    final createdAt = _formatDate(data['createdAt']);

    final statusColor = _statusColor(status);
    final qualityColor = _qualityColor(quality);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: statusColor.withOpacity(0.18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.13),
                child: Icon(_statusIcon(status), color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cropName.trim().isEmpty
                      ? AppLanguage.text('Crop Listing', 'बाली लिस्टिङ')
                      : cropName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _openManageSheet(docId: docId, data: data),
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _cropImage(imageUrl),
          const SizedBox(height: 12),
          _priceBox(price, statusColor),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(label: _statusText(status), color: statusColor),
              _chip(
                label: _qualityText(quality, qualityNe),
                color: qualityColor,
              ),
            ],
          ),
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
            icon: Icons.email,
            label: AppLanguage.text('Farmer', 'किसान'),
            value: sellerEmail.trim().isEmpty
                ? AppLanguage.text('Email not added', 'इमेल थपिएको छैन')
                : sellerEmail,
          ),
          _detailLine(
            icon: Icons.schedule,
            label: AppLanguage.text('Created', 'बनाइएको'),
            value: createdAt,
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.12)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note_alt, color: Colors.orange.shade700, size: 20),
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
            child: OutlinedButton.icon(
              onPressed: () => _openManageSheet(docId: docId, data: data),
              icon: const Icon(Icons.admin_panel_settings),
              label: Text(AppLanguage.text('Admin Action', 'एडमिन कार्य')),
              style: OutlinedButton.styleFrom(
                foregroundColor: statusColor,
                side: BorderSide(color: statusColor.withOpacity(0.45)),
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
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Colors.orange.shade700,
              size: 38,
            ),
            const SizedBox(height: 8),
            Text(
              AppLanguage.text('No crop photo', 'बालीको फोटो छैन'),
              style: TextStyle(
                color: Colors.orange.shade800,
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
              color: Colors.orange.shade50,
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
          const Icon(Icons.search_off, color: Colors.orange, size: 58),
          const SizedBox(height: 12),
          Text(
            AppLanguage.text('No matching listing', 'मिल्ने लिस्टिङ भेटिएन'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Try another search or status filter.',
              'अर्को खोज वा स्थिति फिल्टर प्रयास गर्नुहोस्।',
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
              Icon(icon, size: 58, color: Colors.orange),
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
