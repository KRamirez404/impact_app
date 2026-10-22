class ApiConstants {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static String get originUrl => _baseUrl.endsWith('/api')
      ? _baseUrl.substring(0, _baseUrl.length - 4)
      : _baseUrl;

  static String normalizarBaseUrl(String valor) {
    var url = valor.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String? validarBaseUrl(String valor) {
    final url = normalizarBaseUrl(valor);
    if (url.isEmpty) {
      return 'Ingresa la URL del servidor';
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'URL inválida. Ejemplo: http://192.168.1.10:5000/api';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'La URL debe iniciar con http:// o https://';
    }
    if (!url.endsWith('/api')) {
      return 'La URL debe terminar en /api';
    }
    return null;
  }

  static void aplicarBaseUrl(String valor) {
    _baseUrl = normalizarBaseUrl(valor);
  }

  static void restaurarBaseUrl() {
    _baseUrl = defaultBaseUrl;
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
  static String get privacyPolicy => '$baseUrl/auth/privacy-policy';
  static String get campaigns => '$baseUrl/campaigns';
  static String get myCampaigns => '$baseUrl/campaigns/mine';
  static String get cities => '$baseUrl/cities';
  static String get categories => '$baseUrl/categories';
  static String get donations => '$baseUrl/donations';
  static String get donationCheckout => '$baseUrl/donations/checkout';
  static String donationStatus(int donationId) =>
      '$baseUrl/donations/$donationId/status';
  static String get myDonations => '$baseUrl/donations/mine';
  static String get topDonors => '$baseUrl/donations/top';
  static String campaignDonors(int campaignId) =>
      '$baseUrl/campaigns/$campaignId/donors';
  static String get supports => '$baseUrl/supports';
  static String get supportSummary => '$baseUrl/support/summary';
  static String get supportCampaigns => '$baseUrl/support/campaigns';
  static String supportApprove(int campaignId) =>
      '$baseUrl/support/campaigns/$campaignId/approve';
  static String supportReject(int campaignId) =>
      '$baseUrl/support/campaigns/$campaignId/reject';
  static String supportInvalidate(int campaignId) =>
      '$baseUrl/support/campaigns/$campaignId/invalidate';
  static String supportDelete(int campaignId) =>
      '$baseUrl/support/campaigns/$campaignId/delete';
  static String supportRestore(int campaignId) =>
      '$baseUrl/support/campaigns/$campaignId/restore';
  static String get tracking => '$baseUrl/tracking';
  static String get collectionPoints => '$baseUrl/collection-points';
  static String get ratings => '$baseUrl/ratings';
  static String get likes => '$baseUrl/likes';
  static String get upload => '$baseUrl/upload';
  static String get health => '$baseUrl/health';
}
