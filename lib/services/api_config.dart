class ApiConfig {
  // static const String baseUrl = 'http://34.131.42.218';
  static const String baseUrl = 'https://bck.anaadfoods.com';
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // static const String baseUrl = "http://192.168.29.209:8000";

  static const String paymentUrl = 'http://13.235.242.181:5000';

  /// Panchang may be hosted on a different backend than the main app APIs.
  /// Set this to the correct Panchang host when available.
  ///
  /// Example: 'https://panchang.anaadfoods.com' (no trailing slash)
  static String get panchangBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) return baseUrl;
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  // Panchang Calendar endpoints
  static const String panchangCalenderBase = '/api/panchang-calender/';
  static const String panchangDayEndpoint = '${panchangCalenderBase}day/';
  static const String panchangRangeEndpoint = '${panchangCalenderBase}range/';
  static const String panchangMonthEndpoint = '${panchangCalenderBase}month/';
  static const String panchangFestivalsEndpoint =
      '${panchangCalenderBase}festivals/';
  static const String panchangFestivalSearchEndpoint =
      '${panchangCalenderBase}festivals/search/';
  static const String panchangMuhuratsEndpoint =
      '${panchangCalenderBase}muhurats/';
  static const String panchangVratCalendarEndpoint =
      '${panchangCalenderBase}vrat-calendar/';
  static const String panchangHighlightsEndpoint =
      '${panchangCalenderBase}highlights/';
  static const String panchangBundlesEndpoint =
      '${panchangCalenderBase}bundles/';
  static const String panchangGuidanceTodayEndpoint =
      '${panchangCalenderBase}guidance/today/';
  static const String panchangGuidanceProfileEndpoint =
      '${panchangCalenderBase}guidance/profile/';
  static String panchangFestivalDetailEndpoint(String code) =>
      '${panchangCalenderBase}festivals/$code/';
  // Auth endpoints
  static const String registerEndpoint = '/api/auth/register/';
  static const String loginEndpoint = '/api/auth/token/';
  static const String refreshEndpoint = '/api/auth/token/refresh/';
  static const String favoritesEndpoint = '/api/auth/favorites/';
  static const String profileEndpoint = '/api/auth/profile/';
  static const String testTokenEndpoint = '/api/auth/test-token/';
  static const String sendOtpEndpoint = '/api/auth/send-otp/';
  static const String deactivateEndpoint = '/api/auth/deactivate/';
  static const String deactivateConfirmEndpoint =
      '/api/auth/deactivate_confirm/';

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

  // Order tracking endpoint (returns tracking data for an order)
  static String orderTrackingEndpoint(String orderNumber) =>
      '/api/shiprocket/orders/tracking_by_order/?order_number=$orderNumber';

  // Subscription endpoints
  static const String subscriptionsEndpoint = '/api/subscriptions/';
  static const String subscriptionPlansEndpoint = '/api/subscriptions/plans/';

  // Legal endpoints
  static const String legalEndpoint = '/api/core/legal/latest/';

  // Referral reward endpoints
  static const String referralRewardCountEndpoint =
      '/api/auth/referral_reward_count/';
  static const String referralsEndpoint = '/api/auth/referrals/';

  // User summary endpoint
  static const String userSummaryEndpoint = '/api/core/user-summary/';

  // Headers
  static Map<String, String> getBaseHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  static Map<String, String> getAuthHeaders(String token) {
    return {...getBaseHeaders(), 'Authorization': 'Bearer $token'};
  }
}
