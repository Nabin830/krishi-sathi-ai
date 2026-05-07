import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_language.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _selectedUnitFilter = 'all';

  final List<String> _unitOptions = [
    'kg',
    'quintal',
    'ton',
    'crate',
    'muri',
    'dozen',
    'piece',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _marketPricesStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('marketPrices')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  DateTime _readCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
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

  String _cleanKey(String value) {
    return value.trim().toLowerCase();
  }

  String _readCropName(Map<String, dynamic> data) {
    return (data['cropName'] ??
            data['crop'] ??
            data['name'] ??
            data['crop_name'] ??
            '')
        .toString()
        .trim();
  }

  String _readCropNameNe(Map<String, dynamic> data) {
    return (data['cropNameNe'] ?? data['cropNe'] ?? data['nameNe'] ?? '')
        .toString()
        .trim();
  }

  String _readUnit(Map<String, dynamic> data) {
    return (data['unit'] ?? data['priceUnit'] ?? data['quantityUnit'] ?? 'kg')
        .toString()
        .trim();
  }

  double _readPriceValue(Map<String, dynamic> data) {
    return _toDouble(
      data['priceValue'] ??
          data['marketPrice'] ??
          data['priceEn'] ??
          data['price'] ??
          data['priceText'],
    );
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

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
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

    return docs.where((doc) {
      final data = doc.data();

      final unit = _readUnit(data).toLowerCase();

      if (_selectedUnitFilter != 'all' && unit != _selectedUnitFilter) {
        return false;
      }

      if (query.isEmpty) return true;

      final cropName = _readCropName(data).toLowerCase();
      final cropNameNe = _readCropNameNe(data).toLowerCase();
      final marketName = (data['marketName'] ?? '').toString().toLowerCase();
      final location = (data['location'] ?? '').toString().toLowerCase();
      final trend = (data['trend'] ?? '').toString().toLowerCase();

      return cropName.contains(query) ||
          cropNameNe.contains(query) ||
          marketName.contains(query) ||
          location.contains(query) ||
          trend.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _matchingMarketRecords({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
    required String cropName,
    required String unit,
  }) {
    final cropKey = _cleanKey(cropName);
    final unitKey = _cleanKey(unit);

    if (cropKey.isEmpty || unitKey.isEmpty) {
      return [];
    }

    final matches = <Map<String, dynamic>>[];

    for (final doc in allDocs) {
      final data = doc.data();

      final recordCrop = _cleanKey(_readCropName(data));
      final recordCropNe = _cleanKey(_readCropNameNe(data));
      final recordUnit = _cleanKey(_readUnit(data));
      final price = _readPriceValue(data);

      final sameCrop = recordCrop == cropKey || recordCropNe == cropKey;
      final sameUnit = recordUnit == unitKey;

      if (sameCrop && sameUnit && price > 0) {
        matches.add(data);
      }
    }

    return matches;
  }

  Map<String, dynamic> _marketComparison({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
    required Map<String, dynamic> currentData,
  }) {
    final cropName = _readCropName(currentData);
    final unit = _readUnit(currentData);
    final currentPrice = _readPriceValue(currentData);

    final matches = _matchingMarketRecords(
      allDocs: allDocs,
      cropName: cropName,
      unit: unit,
    );

    if (cropName.trim().isEmpty || currentPrice <= 0) {
      return {
        'status': 'invalid',
        'titleEn': 'Cannot compare this price',
        'titleNe': 'यो मूल्य तुलना गर्न सकिँदैन',
        'messageEn':
            'Crop name or price is missing. Please add a proper crop name and price first.',
        'messageNe':
            'बालीको नाम वा मूल्य छैन। कृपया पहिले सही बालीको नाम र मूल्य राख्नुहोस्।',
        'average': 0.0,
        'count': matches.length,
      };
    }

    if (matches.isEmpty) {
      return {
        'status': 'not_enough',
        'titleEn': 'No matching market data',
        'titleNe': 'मिल्ने बजार डाटा छैन',
        'messageEn':
            'There is no saved market price data for $cropName per $unit. Add real prices for the same crop and same unit first.',
        'messageNe':
            '$cropName प्रति $unit को लागि बजार मूल्य डाटा छैन। पहिले यही बाली र यही unit को वास्तविक बजार मूल्य थप्नुहोस्।',
        'average': 0.0,
        'count': matches.length,
      };
    }

    double total = 0;

    for (final item in matches) {
      total += _readPriceValue(item);
    }

    final average = total / matches.length;
    final difference = currentPrice - average;
    final percentageDifference = average <= 0
        ? 0
        : (difference / average) * 100;

    if (matches.length == 1) {
      return {
        'status': 'single',
        'titleEn': '$cropName has only one saved price',
        'titleNe': '$cropName को एउटा मात्र मूल्य सेभ छ',
        'messageEn':
            'Only one saved record was found for $cropName per $unit. Current saved price is Rs. ${_formatPrice(currentPrice)}/$unit. Add more real market prices from nearby markets to calculate a better average.',
        'messageNe':
            '$cropName प्रति $unit को एउटा मात्र मूल्य भेटियो। अहिले सेभ भएको मूल्य रु. ${_formatPrice(currentPrice)}/$unit हो। राम्रो औसत निकाल्न नजिकका बजारबाट थप वास्तविक मूल्य थप्नुहोस्।',
        'average': average,
        'count': matches.length,
      };
    }

    if (percentageDifference >= 15) {
      return {
        'status': 'above',
        'titleEn': '$cropName price is above market average',
        'titleNe': '$cropName को मूल्य बजार औसतभन्दा माथि छ',
        'messageEn':
            'Your price is Rs. ${_formatPrice(currentPrice)}/$unit. Saved market average is around Rs. ${_formatPrice(average)}/$unit based on ${matches.length} records. Buyers may negotiate unless your crop quality is very good, fresh, or transport cost is included.',
        'messageNe':
            'तपाईंको मूल्य रु. ${_formatPrice(currentPrice)}/$unit छ। ${matches.length} वटा रेकर्ड अनुसार बजार औसत करिब रु. ${_formatPrice(average)}/$unit छ। गुणस्तर धेरै राम्रो, ताजा वा ढुवानी समावेश नभए खरिदकर्ताले मूल्य घटाउन खोज्न सक्छन्।',
        'average': average,
        'count': matches.length,
      };
    }

    if (percentageDifference <= -15) {
      return {
        'status': 'below',
        'titleEn': '$cropName price is below market average',
        'titleNe': '$cropName को मूल्य बजार औसतभन्दा कम छ',
        'messageEn':
            'Your price is Rs. ${_formatPrice(currentPrice)}/$unit. Saved market average is around Rs. ${_formatPrice(average)}/$unit based on ${matches.length} records. This may sell faster, but check quality, transport cost, packaging cost, and profit before selling.',
        'messageNe':
            'तपाईंको मूल्य रु. ${_formatPrice(currentPrice)}/$unit छ। ${matches.length} वटा रेकर्ड अनुसार बजार औसत करिब रु. ${_formatPrice(average)}/$unit छ। छिटो बिक्री हुन सक्छ तर बेच्नुअघि गुणस्तर, ढुवानी, प्याकिङ खर्च र नाफा जाँच गर्नुहोस्।',
        'average': average,
        'count': matches.length,
      };
    }

    return {
      'status': 'around',
      'titleEn': '$cropName price is close to market average',
      'titleNe': '$cropName को मूल्य बजार औसत नजिक छ',
      'messageEn':
          'Your price is Rs. ${_formatPrice(currentPrice)}/$unit. Saved market average is around Rs. ${_formatPrice(average)}/$unit based on ${matches.length} records. This looks reasonable, but still compare nearby market price and transport cost.',
      'messageNe':
          'तपाईंको मूल्य रु. ${_formatPrice(currentPrice)}/$unit छ। ${matches.length} वटा रेकर्ड अनुसार बजार औसत करिब रु. ${_formatPrice(average)}/$unit छ। यो उचित देखिन्छ तर नजिकको बजार मूल्य र ढुवानी खर्च पनि तुलना गर्नुहोस्।',
      'average': average,
      'count': matches.length,
    };
  }

  void _showComparisonSheet({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
    required Map<String, dynamic> data,
  }) {
    final comparison = _marketComparison(allDocs: allDocs, currentData: data);

    final status = comparison['status'].toString();

    Color color = Colors.green;
    IconData icon = Icons.balance;

    if (status == 'above') {
      color = Colors.orange;
      icon = Icons.trending_up;
    } else if (status == 'below') {
      color = Colors.blue;
      icon = Icons.trending_down;
    } else if (status == 'not_enough' ||
        status == 'invalid' ||
        status == 'single') {
      color = Colors.red;
      icon = Icons.info_outline;
    }

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
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLanguage.text('Market Comparison', 'बजार तुलना'),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLanguage.text(
                      comparison['titleEn'].toString(),
                      comparison['titleNe'].toString(),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLanguage.text(
                      comparison['messageEn'].toString(),
                      comparison['messageNe'].toString(),
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _comparisonTip(
                    icon: Icons.check_circle,
                    text: AppLanguage.text(
                      'Check nearby market price before selling.',
                      'बेच्नुअघि नजिकको बजार मूल्य जाँच गर्नुहोस्।',
                    ),
                  ),
                  _comparisonTip(
                    icon: Icons.local_shipping,
                    text: AppLanguage.text(
                      'Include transport and packaging cost in your final price.',
                      'अन्तिम मूल्यमा ढुवानी र प्याकिङ खर्च पनि सोच्नुहोस्।',
                    ),
                  ),
                  _comparisonTip(
                    icon: Icons.verified,
                    text: AppLanguage.text(
                      'If your crop quality is better, a higher price may be acceptable.',
                      'बालीको गुणस्तर राम्रो छ भने अलि बढी मूल्य उचित हुन सक्छ।',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLanguage.text(
                      'This comparison uses your saved market price records in this app. It is not an official government price.',
                      'यो तुलना यस app मा तपाईंले सेभ गरेका बजार मूल्य रेकर्डमा आधारित हो। यो सरकारी आधिकारिक मूल्य होइन।',
                    ),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _comparisonTip({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade700, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
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

  Future<void> _openAddPriceSheet() async {
    final formKey = GlobalKey<FormState>();

    final cropNameController = TextEditingController();
    final cropNameNeController = TextEditingController();
    final marketNameController = TextEditingController();
    final locationController = TextEditingController();
    final priceController = TextEditingController();
    final noteController = TextEditingController();

    String selectedUnit = 'kg';
    String selectedTrend = 'stable';
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4F8F3),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> saveMarketPrice() async {
              if (!formKey.currentState!.validate()) return;

              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }

                _showMessage(
                  AppLanguage.text(
                    'You must be logged in',
                    'तपाईं लगइन भएको हुनुपर्छ',
                  ),
                );
                return;
              }

              final priceValue = _toDouble(priceController.text);

              if (priceValue <= 0) {
                _showMessage(
                  AppLanguage.text(
                    'Please enter a valid price',
                    'कृपया सही मूल्य लेख्नुहोस्',
                  ),
                );
                return;
              }

              setSheetState(() {
                isSaving = true;
              });

              try {
                final cropName = cropNameController.text.trim();
                final cropNameNe = cropNameNeController.text.trim();

                await FirebaseFirestore.instance
                    .collection('marketPrices')
                    .add({
                      'userId': user.uid,
                      'userEmail': user.email,
                      'cropName': cropName,
                      'cropNameNe': cropNameNe,
                      'cropKey': _cleanKey(cropName),
                      'cropKeyNe': _cleanKey(cropNameNe),
                      'marketName': marketNameController.text.trim(),
                      'location': locationController.text.trim(),
                      'priceValue': priceValue,
                      'unit': selectedUnit,
                      'price': 'Rs. ${_formatPrice(priceValue)}/$selectedUnit',
                      'trend': selectedTrend,
                      'note': noteController.text.trim(),
                      'status': 'active',
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                if (!mounted) return;

                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }

                _showMessage(
                  AppLanguage.text(
                    'Market price added successfully ✅',
                    'बजार मूल्य सफलतापूर्वक थपियो ✅',
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                if (sheetContext.mounted) {
                  setSheetState(() {
                    isSaving = false;
                  });
                }

                _showMessage(
                  AppLanguage.text(
                    'Failed to add market price: $e',
                    'बजार मूल्य थप्न समस्या भयो: $e',
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _cardDecoration(),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLanguage.text(
                            'Add Market Price',
                            'बजार मूल्य थप्नुहोस्',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _sheetTextField(
                          controller: cropNameController,
                          label: AppLanguage.text('Crop Name', 'बालीको नाम'),
                          icon: Icons.eco,
                          requiredText: AppLanguage.text(
                            'Please enter crop name',
                            'कृपया बालीको नाम लेख्नुहोस्',
                          ),
                        ),
                        _sheetTextField(
                          controller: cropNameNeController,
                          label: AppLanguage.text(
                            'Crop Name in Nepali optional',
                            'नेपालीमा बालीको नाम वैकल्पिक',
                          ),
                          icon: Icons.language,
                          requiredField: false,
                        ),
                        _sheetTextField(
                          controller: marketNameController,
                          label: AppLanguage.text('Market Name', 'बजारको नाम'),
                          icon: Icons.store,
                          requiredText: AppLanguage.text(
                            'Please enter market name',
                            'कृपया बजारको नाम लेख्नुहोस्',
                          ),
                        ),
                        _sheetTextField(
                          controller: locationController,
                          label: AppLanguage.text('Location', 'स्थान'),
                          icon: Icons.place,
                          requiredText: AppLanguage.text(
                            'Please enter location',
                            'कृपया स्थान लेख्नुहोस्',
                          ),
                        ),
                        _sheetTextField(
                          controller: priceController,
                          label: AppLanguage.text('Price', 'मूल्य'),
                          icon: Icons.payments,
                          keyboardType: TextInputType.number,
                          requiredText: AppLanguage.text(
                            'Please enter price',
                            'कृपया मूल्य लेख्नुहोस्',
                          ),
                        ),
                        _sheetDropdown(
                          label: AppLanguage.text('Unit', 'एकाइ'),
                          value: selectedUnit,
                          items: _unitOptions,
                          icon: Icons.scale,
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              selectedUnit = value;
                            });
                          },
                        ),
                        _sheetDropdown(
                          label: AppLanguage.text(
                            'Market Trend',
                            'बजार अवस्था',
                          ),
                          value: selectedTrend,
                          items: const [
                            'stable',
                            'high demand',
                            'low demand',
                            'price rising',
                            'price falling',
                          ],
                          icon: Icons.trending_up,
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              selectedTrend = value;
                            });
                          },
                        ),
                        _sheetTextField(
                          controller: noteController,
                          label: AppLanguage.text(
                            'Note optional',
                            'नोट वैकल्पिक',
                          ),
                          icon: Icons.note_alt,
                          requiredField: false,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : saveMarketPrice,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              isSaving
                                  ? AppLanguage.text(
                                      'Saving...',
                                      'सेभ हुँदैछ...',
                                    )
                                  : AppLanguage.text(
                                      'Save Market Price',
                                      'बजार मूल्य सेभ गर्नुहोस्',
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String requiredText = '',
    bool requiredField = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
        validator: (value) {
          if (!requiredField) return null;

          if (value == null || value.trim().isEmpty) {
            return requiredText;
          }

          if (keyboardType == TextInputType.number) {
            final number = _toDouble(value);
            if (number <= 0) {
              return AppLanguage.text(
                'Please enter a valid number',
                'कृपया सही नम्बर लेख्नुहोस्',
              );
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _sheetDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Market Prices', 'बजार मूल्य'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButton: user == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openAddPriceSheet,
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(AppLanguage.text('Add Price', 'मूल्य थप्नुहोस्')),
                ),
          body: SafeArea(
            child: user == null
                ? _loginState()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _marketPricesStream(),
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
                        return _emptyState();
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _headerCard(docs.length),
                          const SizedBox(height: 16),
                          _searchCard(),
                          const SizedBox(height: 12),
                          _unitFilters(),
                          const SizedBox(height: 16),
                          if (filteredDocs.isEmpty)
                            _emptySearchCard()
                          else
                            ...filteredDocs.map((doc) {
                              return _priceCard(
                                data: doc.data(),
                                allDocs: docs,
                              );
                            }),
                          const SizedBox(height: 90),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _loginState() {
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
              const Icon(Icons.lock, size: 58, color: Colors.green),
              const SizedBox(height: 14),
              Text(
                AppLanguage.text(
                  'Please login first',
                  'कृपया पहिले लगइन गर्नुहोस्',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLanguage.text(
                  'Your saved market prices will appear after login.',
                  'लगइन गरेपछि तपाईंको सेभ बजार मूल्य देखिनेछ।',
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

  Widget _headerCard(int count) {
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
            child: Icon(Icons.store, color: Colors.green, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              AppLanguage.text(
                '$count saved market price records',
                '$count बजार मूल्य रेकर्ड सेभ छन्',
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
            'Search crop, market or location',
            'बाली, बजार वा स्थान खोज्नुहोस्',
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

  Widget _unitFilters() {
    final filters = ['all', ..._unitOptions];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((unit) {
        final selected = _selectedUnitFilter == unit;

        return ChoiceChip(
          selected: selected,
          label: Text(unit == 'all' ? AppLanguage.text('All', 'सबै') : unit),
          selectedColor: Colors.green.shade700,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
          side: BorderSide(color: Colors.green.withOpacity(0.25)),
          onSelected: (_) {
            setState(() {
              _selectedUnitFilter = unit;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _priceCard({
    required Map<String, dynamic> data,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs,
  }) {
    final cropName = _displayText(_readCropName(data), _readCropNameNe(data));

    final marketName = (data['marketName'] ?? '').toString();
    final location = (data['location'] ?? '').toString();
    final priceValue = _readPriceValue(data);
    final unit = _readUnit(data);
    final price = (data['price'] ?? '').toString();
    final trend = (data['trend'] ?? 'stable').toString();
    final note = (data['note'] ?? '').toString();
    final createdAt = _formatDate(data['createdAt']);

    final trendColor = _trendColor(trend);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: trendColor.withOpacity(0.16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: trendColor.withOpacity(0.12),
                child: Icon(Icons.store, color: trendColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cropName.trim().isEmpty
                      ? AppLanguage.text('Crop Price', 'बाली मूल्य')
                      : cropName,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.14)),
                ),
                child: Text(
                  price.trim().isEmpty
                      ? 'Rs. ${_formatPrice(priceValue)}/$unit'
                      : price,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailLine(
            icon: Icons.store,
            label: AppLanguage.text('Market', 'बजार'),
            value: marketName.trim().isEmpty
                ? AppLanguage.text('Market not added', 'बजार थपिएको छैन')
                : marketName,
          ),
          _detailLine(
            icon: Icons.place,
            label: AppLanguage.text('Location', 'स्थान'),
            value: location.trim().isEmpty
                ? AppLanguage.text('Location not added', 'स्थान थपिएको छैन')
                : location,
          ),
          _detailLine(
            icon: Icons.scale,
            label: AppLanguage.text('Unit', 'एकाइ'),
            value: unit,
          ),
          _detailLine(
            icon: Icons.trending_up,
            label: AppLanguage.text('Trend', 'बजार अवस्था'),
            value: _trendText(trend),
          ),
          _detailLine(
            icon: Icons.schedule,
            label: AppLanguage.text('Added', 'थपिएको'),
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
              onPressed: () {
                _showComparisonSheet(allDocs: allDocs, data: data);
              },
              icon: const Icon(Icons.balance),
              label: Text(
                AppLanguage.text(
                  'Compare with Market Average',
                  'बजार औसतसँग तुलना गर्नुहोस्',
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
            AppLanguage.text('No matching price', 'मिल्ने मूल्य भेटिएन'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            AppLanguage.text(
              'Try another crop, market or location.',
              'अर्को बाली, बजार वा स्थान खोज्नुहोस्।',
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
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.store, size: 58, color: Colors.green),
              const SizedBox(height: 14),
              Text(
                AppLanguage.text(
                  'No market prices yet',
                  'अहिलेसम्म बजार मूल्य छैन',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLanguage.text(
                  'Tap Add Price to save real market prices.',
                  'वास्तविक बजार मूल्य सेभ गर्न Add Price थिच्नुहोस्।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openAddPriceSheet,
                icon: const Icon(Icons.add),
                label: Text(AppLanguage.text('Add Price', 'मूल्य थप्नुहोस्')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
