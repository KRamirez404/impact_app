class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String me = '$baseUrl/auth/me';
  static const String campaigns = '$baseUrl/campaigns';
  static const String myCampaigns = '$baseUrl/campaigns/mine';
  static const String cities = '$baseUrl/cities';
  static const String categories = '$baseUrl/categories';
  static const String donations = '$baseUrl/donations';
  static const String myDonations = '$baseUrl/donations/mine';
  static const String supports = '$baseUrl/supports';
  static const String tracking = '$baseUrl/tracking';
  static const String collectionPoints = '$baseUrl/collection-points';
  static const String ratings = '$baseUrl/ratings';
  static const String health = '$baseUrl/health';
}
