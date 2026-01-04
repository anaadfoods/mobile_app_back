class ApiConfig {
  // static const String baseUrl = 'http://34.131.42.218';
  static const String baseUrl = 'https://bac.anaadfoods.com';
  static const String paymentUrl = 'http://34.131.42.218:5000';
  // Auth endpoints
  static const String registerEndpoint = '/api/auth/register/';
  static const String loginEndpoint = '/api/auth/token/';
  static const String refreshEndpoint = '/api/auth/token/refresh/';
  static const String favoritesEndpoint = '/api/auth/favorites/';
  static const String profileEndpoint = '/api/auth/profile/';
  static const String testTokenEndpoint = '/api/auth/test-token/';
  static const String sendOtpEndpoint = '/api/auth/send-otp/';

  // Product endpoints
  static const String productsEndpoint = '/api/products/';
  static const String featuredProductsEndpoint = '/api/products/featured/';
  static const String categoriesEndpoint = '/api/categories/';

  // Cart endpoints
  static const String cartEndpoint = '/api/cart/';
  static const String getcartEndpoint = '/api/cart/details/';
  static const String cartItemsEndpoint = '/api/cart/items/';

  // Order endpoints
  static const String ordersEndpoint = '/api/orders/';
  static const String checkoutEndpoint = '/api/checkout/';
  static const String createOrderEndpoint = '/api/orders/create/';
  static const String getorders = '/api/orders/';
  static const String userDetailsEndpoint = '/api/user/details/';

  // Subscription endpoints
  static const String subscriptionsEndpoint = '/api/subscriptions/';
  static const String subscriptionPlansEndpoint = '/api/subscriptions/plans/';

  // Legal endpoints
  static const String legalEndpoint = '/api/core/legal/latest/';

  // Referral reward endpoints
  static const String referralRewardCountEndpoint =
      '/api/auth/referral_reward_count/';
  static const String referralsEndpoint = '/api/auth/referrals/';

  // Headers
  static Map<String, String> getBaseHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  static Map<String, String> getAuthHeaders(String token) {
    return {...getBaseHeaders(), 'Authorization': 'Bearer $token'};
  }
}
