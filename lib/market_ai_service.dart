import 'package:cloud_firestore/cloud_firestore.dart';

class MarketAiResult {
  final bool success;
  final String marketAiStatus;
  final String marketAiMessage;
  final String marketAiMessageNe;

  final String aiMarketTitle;
  final String aiMarketTitleNe;
  final String aiMarketRisk;
  final String aiMarketRiskNe;
  final String aiMarketSummary;
  final String aiMarketSummaryNe;
  final List<String> aiMarketActions;
  final List<String> aiMarketActionsNe;

  MarketAiResult({
    required this.success,
    required this.marketAiStatus,
    required this.marketAiMessage,
    required this.marketAiMessageNe,
    required this.aiMarketTitle,
    required this.aiMarketTitleNe,
    required this.aiMarketRisk,
    required this.aiMarketRiskNe,
    required this.aiMarketSummary,
    required this.aiMarketSummaryNe,
    required this.aiMarketActions,
    required this.aiMarketActionsNe,
  });

  factory MarketAiResult.fromJson(Map<String, dynamic> json) {
    return MarketAiResult(
      success: json['success'] == true,
      marketAiStatus: (json['marketAiStatus'] ?? '').toString(),
      marketAiMessage: (json['marketAiMessage'] ?? '').toString(),
      marketAiMessageNe: (json['marketAiMessageNe'] ?? '').toString(),
      aiMarketTitle: (json['aiMarketTitle'] ?? '').toString(),
      aiMarketTitleNe: (json['aiMarketTitleNe'] ?? '').toString(),
      aiMarketRisk: (json['aiMarketRisk'] ?? '').toString(),
      aiMarketRiskNe: (json['aiMarketRiskNe'] ?? '').toString(),
      aiMarketSummary: (json['aiMarketSummary'] ?? '').toString(),
      aiMarketSummaryNe: (json['aiMarketSummaryNe'] ?? '').toString(),
      aiMarketActions: _toStringList(json['aiMarketActions']),
      aiMarketActionsNe: _toStringList(json['aiMarketActionsNe']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'marketAiStatus': marketAiStatus,
      'marketAiMessage': marketAiMessage,
      'marketAiMessageNe': marketAiMessageNe,
      'aiMarketTitle': aiMarketTitle,
      'aiMarketTitleNe': aiMarketTitleNe,
      'aiMarketRisk': aiMarketRisk,
      'aiMarketRiskNe': aiMarketRiskNe,
      'aiMarketSummary': aiMarketSummary,
      'aiMarketSummaryNe': aiMarketSummaryNe,
      'aiMarketActions': aiMarketActions,
      'aiMarketActionsNe': aiMarketActionsNe,
    };
  }

  static List<String> _toStringList(dynamic value) {
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
}

class MarketAiService {
  static String _cleanKey(String value) {
    return value.trim().toLowerCase();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
  }

  static Future<List<Map<String, dynamic>>> _getMatchingMarketPrices({
    required String cropName,
    required String cropNameNe,
    required String unit,
  }) async {
    final cropKey = _cleanKey(cropName);
    final cropNeKey = _cleanKey(cropNameNe);
    final unitKey = _cleanKey(unit);

    if (cropKey.isEmpty && cropNeKey.isEmpty) {
      return [];
    }

    if (unitKey.isEmpty) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('marketPrices')
        .where('unit', isEqualTo: unit)
        .get();

    final matches = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final savedCropName = _cleanKey((data['cropName'] ?? '').toString());
      final savedCropNameNe = _cleanKey((data['cropNameNe'] ?? '').toString());
      final savedCropKey = _cleanKey((data['cropKey'] ?? '').toString());
      final savedCropKeyNe = _cleanKey((data['cropKeyNe'] ?? '').toString());
      final savedUnit = _cleanKey((data['unit'] ?? '').toString());
      final savedPrice = _toDouble(data['priceValue']);

      final sameUnit = savedUnit == unitKey;

      final sameCrop =
          savedCropName == cropKey ||
          savedCropNameNe == cropKey ||
          savedCropKey == cropKey ||
          savedCropKeyNe == cropKey ||
          savedCropName == cropNeKey ||
          savedCropNameNe == cropNeKey ||
          savedCropKey == cropNeKey ||
          savedCropKeyNe == cropNeKey;

      if (sameCrop && sameUnit && savedPrice > 0) {
        matches.add(data);
      }
    }

    return matches;
  }

  static Future<MarketAiResult> getMarketAiAdvice({
    required String cropName,
    required String cropNameNe,
    required double price,
    required String unit,
    required String marketName,
    required String location,
    required String trend,
    required String note,
  }) async {
    final cleanCropName = cropName.trim();
    final cleanCropNameNe = cropNameNe.trim();
    final cleanUnit = unit.trim();

    if (cleanCropName.isEmpty && cleanCropNameNe.isEmpty) {
      return MarketAiResult(
        success: false,
        marketAiStatus: 'missing_crop',
        marketAiMessage: 'Crop name is missing.',
        marketAiMessageNe: 'बालीको नाम छैन।',
        aiMarketTitle: 'Cannot create selling advice',
        aiMarketTitleNe: 'बिक्री सुझाव बनाउन सकिँदैन',
        aiMarketRisk: 'Missing crop name',
        aiMarketRiskNe: 'बालीको नाम छैन',
        aiMarketSummary:
            'Please enter a proper crop name before creating selling advice.',
        aiMarketSummaryNe:
            'बिक्री सुझाव बनाउनुअघि कृपया सही बालीको नाम लेख्नुहोस्।',
        aiMarketActions: [
          'Enter the crop name clearly.',
          'Use the same crop name when adding market price records.',
          'Add at least two saved market prices for better comparison.',
        ],
        aiMarketActionsNe: [
          'बालीको नाम स्पष्ट रूपमा लेख्नुहोस्।',
          'बजार मूल्य थप्दा पनि उही बालीको नाम प्रयोग गर्नुहोस्।',
          'राम्रो तुलना गर्न कम्तीमा दुईवटा बजार मूल्य रेकर्ड थप्नुहोस्।',
        ],
      );
    }

    if (price <= 0) {
      return MarketAiResult(
        success: false,
        marketAiStatus: 'missing_price',
        marketAiMessage: 'Price is missing or invalid.',
        marketAiMessageNe: 'मूल्य छैन वा गलत छ।',
        aiMarketTitle: 'Cannot create selling advice',
        aiMarketTitleNe: 'बिक्री सुझाव बनाउन सकिँदैन',
        aiMarketRisk: 'Missing price',
        aiMarketRiskNe: 'मूल्य छैन',
        aiMarketSummary:
            'Please enter a valid selling price before creating advice.',
        aiMarketSummaryNe: 'सुझाव बनाउनुअघि कृपया सही बिक्री मूल्य राख्नुहोस्।',
        aiMarketActions: [
          'Enter a valid price greater than zero.',
          'Check the unit carefully.',
          'Compare with saved market prices before selling.',
        ],
        aiMarketActionsNe: [
          'शून्यभन्दा बढी सही मूल्य राख्नुहोस्।',
          'एकाइ राम्रोसँग जाँच गर्नुहोस्।',
          'बेच्नु अघि सेभ गरिएका बजार मूल्यसँग तुलना गर्नुहोस्।',
        ],
      );
    }

    final matches = await _getMatchingMarketPrices(
      cropName: cleanCropName,
      cropNameNe: cleanCropNameNe,
      unit: cleanUnit,
    );

    final displayCrop = cleanCropName.isNotEmpty
        ? cleanCropName
        : cleanCropNameNe;

    if (matches.length < 2) {
      return MarketAiResult(
        success: true,
        marketAiStatus: 'not_enough_data',
        marketAiMessage: 'Not enough saved market data.',
        marketAiMessageNe: 'पर्याप्त सेभ गरिएको बजार डाटा छैन।',
        aiMarketTitle: 'Not enough market records for $displayCrop',
        aiMarketTitleNe: '$displayCrop को लागि पर्याप्त बजार रेकर्ड छैन',
        aiMarketRisk: 'Need more market data',
        aiMarketRiskNe: 'थप बजार डाटा चाहिन्छ',
        aiMarketSummary:
            'Your selling price is Rs. ${_formatPrice(price)}/$cleanUnit. I found only ${matches.length} saved matching market record for $displayCrop per $cleanUnit. Because there is not enough saved data, this app cannot give a reliable average price yet.',
        aiMarketSummaryNe:
            'तपाईंको बिक्री मूल्य रु. ${_formatPrice(price)}/$cleanUnit छ। $displayCrop प्रति $cleanUnit का लागि ${matches.length} वटा मात्र मिल्ने बजार रेकर्ड भेटियो। पर्याप्त डाटा नभएकाले अहिले भरपर्दो औसत मूल्य दिन सकिँदैन।',
        aiMarketActions: [
          'Add more real market prices for this crop and unit.',
          'Check nearby market price manually before selling.',
          'Include transport, packaging and freshness in final price.',
        ],
        aiMarketActionsNe: [
          'यो बाली र एकाइका लागि थप वास्तविक बजार मूल्य थप्नुहोस्।',
          'बेच्नु अघि नजिकको बजार मूल्य आफैं जाँच गर्नुहोस्।',
          'अन्तिम मूल्यमा ढुवानी, प्याकिङ र ताजापन पनि सोच्नुहोस्।',
        ],
      );
    }

    double total = 0;

    for (final item in matches) {
      total += _toDouble(item['priceValue']);
    }

    final average = total / matches.length;
    final difference = price - average;
    final percentageDifference = average == 0
        ? 0
        : (difference / average) * 100;

    if (percentageDifference >= 15) {
      return MarketAiResult(
        success: true,
        marketAiStatus: 'above_average',
        marketAiMessage: 'Price is above saved market average.',
        marketAiMessageNe: 'मूल्य सेभ गरिएको बजार औसतभन्दा माथि छ।',
        aiMarketTitle: '$displayCrop price is above saved market average',
        aiMarketTitleNe:
            '$displayCrop को मूल्य सेभ गरिएको बजार औसतभन्दा माथि छ',
        aiMarketRisk: 'High price',
        aiMarketRiskNe: 'उच्च मूल्य',
        aiMarketSummary:
            'Your price is Rs. ${_formatPrice(price)}/$cleanUnit. The saved market average for $displayCrop is around Rs. ${_formatPrice(average)}/$cleanUnit based on ${matches.length} saved records. Your price is about ${percentageDifference.toStringAsFixed(1)}% higher than the saved average.',
        aiMarketSummaryNe:
            'तपाईंको मूल्य रु. ${_formatPrice(price)}/$cleanUnit छ। ${matches.length} वटा सेभ रेकर्ड अनुसार $displayCrop को औसत बजार मूल्य करिब रु. ${_formatPrice(average)}/$cleanUnit छ। तपाईंको मूल्य सेभ औसतभन्दा करिब ${percentageDifference.toStringAsFixed(1)}% बढी छ।',
        aiMarketActions: [
          'Explain quality, freshness or transport cost to buyers.',
          'Be ready for buyers to negotiate the price.',
          'Lower the price if nearby markets are cheaper.',
        ],
        aiMarketActionsNe: [
          'खरिदकर्तालाई गुणस्तर, ताजापन वा ढुवानी खर्च स्पष्ट गर्नुहोस्।',
          'खरिदकर्ताले मूल्य घटाउन खोज्न सक्छन् भनेर तयार हुनुहोस्।',
          'नजिकको बजार सस्तो छ भने मूल्य घटाउने सोच्नुहोस्।',
        ],
      );
    }

    if (percentageDifference <= -15) {
      return MarketAiResult(
        success: true,
        marketAiStatus: 'below_average',
        marketAiMessage: 'Price is below saved market average.',
        marketAiMessageNe: 'मूल्य सेभ गरिएको बजार औसतभन्दा कम छ।',
        aiMarketTitle: '$displayCrop price is below saved market average',
        aiMarketTitleNe: '$displayCrop को मूल्य सेभ गरिएको बजार औसतभन्दा कम छ',
        aiMarketRisk: 'Low price',
        aiMarketRiskNe: 'कम मूल्य',
        aiMarketSummary:
            'Your price is Rs. ${_formatPrice(price)}/$cleanUnit. The saved market average for $displayCrop is around Rs. ${_formatPrice(average)}/$cleanUnit based on ${matches.length} saved records. Your price is about ${percentageDifference.abs().toStringAsFixed(1)}% lower than the saved average.',
        aiMarketSummaryNe:
            'तपाईंको मूल्य रु. ${_formatPrice(price)}/$cleanUnit छ। ${matches.length} वटा सेभ रेकर्ड अनुसार $displayCrop को औसत बजार मूल्य करिब रु. ${_formatPrice(average)}/$cleanUnit छ। तपाईंको मूल्य सेभ औसतभन्दा करिब ${percentageDifference.abs().toStringAsFixed(1)}% कम छ।',
        aiMarketActions: [
          'This price may sell faster.',
          'Check your cost before selling too cheaply.',
          'Increase price if crop quality and freshness are good.',
        ],
        aiMarketActionsNe: [
          'यो मूल्यमा छिटो बिक्री हुन सक्छ।',
          'धेरै सस्तो बेच्नु अघि आफ्नो लागत जाँच गर्नुहोस्।',
          'गुणस्तर र ताजापन राम्रो छ भने मूल्य बढाउन सकिन्छ।',
        ],
      );
    }

    return MarketAiResult(
      success: true,
      marketAiStatus: 'near_average',
      marketAiMessage: 'Price is close to saved market average.',
      marketAiMessageNe: 'मूल्य सेभ गरिएको बजार औसत नजिक छ।',
      aiMarketTitle: '$displayCrop price is close to saved market average',
      aiMarketTitleNe: '$displayCrop को मूल्य सेभ गरिएको बजार औसत नजिक छ',
      aiMarketRisk: 'Reasonable price',
      aiMarketRiskNe: 'उचित मूल्य',
      aiMarketSummary:
          'Your price is Rs. ${_formatPrice(price)}/$cleanUnit. The saved market average for $displayCrop is around Rs. ${_formatPrice(average)}/$cleanUnit based on ${matches.length} saved records. This price looks reasonable compared with saved market data.',
      aiMarketSummaryNe:
          'तपाईंको मूल्य रु. ${_formatPrice(price)}/$cleanUnit छ। ${matches.length} वटा सेभ रेकर्ड अनुसार $displayCrop को औसत बजार मूल्य करिब रु. ${_formatPrice(average)}/$cleanUnit छ। सेभ गरिएको बजार डाटासँग तुलना गर्दा यो मूल्य उचित देखिन्छ।',
      aiMarketActions: [
        'Keep this price if crop quality is normal.',
        'Mention freshness and pickup location clearly.',
        'Still check nearby market price before final selling.',
      ],
      aiMarketActionsNe: [
        'बालीको गुणस्तर सामान्य छ भने यो मूल्य राख्न सकिन्छ।',
        'ताजापन र लिन आउने स्थान स्पष्ट लेख्नुहोस्।',
        'अन्तिम बिक्री अघि नजिकको बजार मूल्य पनि जाँच गर्नुहोस्।',
      ],
    );
  }
}
