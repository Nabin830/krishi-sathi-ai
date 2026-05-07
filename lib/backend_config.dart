class BackendConfig {
  // For now keep this empty because your backend is not connected yet.
  //
  // Later example for iOS simulator / Mac:
  // static const String baseUrl = 'http://127.0.0.1:5000';
  //
  // For Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:5000';
  //
  // For real phone, use your Mac local IP:
  // static const String baseUrl = 'http://192.168.1.10:5000';

  static const String baseUrl = '';

  // Keep endpoint paths only here.
  static const String scanPlantPath = '/api/scan-plant';
  static const String weatherAiSummaryPath = '/api/weather-ai-summary';

  static bool get isBackendConnected {
    return baseUrl.trim().isNotEmpty;
  }

  static String _joinUrl(String base, String path) {
    if (base.trim().isEmpty) {
      return '';
    }

    final cleanBaseUrl = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return '$cleanBaseUrl$cleanPath';
  }

  static String get scanPlantEndpoint {
    return _joinUrl(baseUrl, scanPlantPath);
  }

  static String get weatherAiSummaryEndpoint {
    return _joinUrl(baseUrl, weatherAiSummaryPath);
  }

  static String get fullScanPlantUrl {
    return scanPlantEndpoint;
  }

  static String get connectionStatusText {
    if (isBackendConnected) {
      return 'Backend connected';
    }

    return 'Backend not connected';
  }
}
