import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        return envUrl.trim();
      }
    } catch (_) {}
    return 'https://bck-dev.anaadfoods.com';
  }

  /// Toggle flag for expected delivery date
  static bool get showExpectedDeliveryDate {
    try {
      return (dotenv.env['SHOW_EXPECTED_DELIVERY_DATE'] ?? 'true')
              .toLowerCase() ==
          'true';
    } catch (_) {
      return true;
    }
  }

  static const String alternativeDeliveryText =
      "delivery will be start from Aug 2026 first week";

  /// Juspay payment bridge - HTTPS endpoint with certificate pinning
  static const String paymentUrl = 'https://payment.anaadfoods.com';
  static const String _paymentCertificatePins = String.fromEnvironment(
    'PAYMENT_CERT_SHA256_PINS',
  );
  static List<String> get paymentCertificateSha256Pins =>
      _paymentCertificatePins
          .split(',')
          .map((pin) => pin.trim())
          .where((pin) => pin.isNotEmpty)
          .toList(growable: false);

  /// Panchang base URL (falls back to API_BASE_URL or baseUrl)
  static String get panchangBaseUrl {
    try {
      final envUrl =
          dotenv.env['PANCHANG_BASE_URL'] ?? dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        final trimmed = envUrl.trim();
        return trimmed.endsWith('/')
            ? trimmed.substring(0, trimmed.length - 1)
            : trimmed;
      }
    } catch (_) {}
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

  // Panchang Encyclopedia endpoints (admin-configurable Vedic reference data)
  static const String encyclopediaLunarMonths =
      '${panchangCalenderBase}encyclopedia/lunar-months/';
  static const String encyclopediaPakshas =
      '${panchangCalenderBase}encyclopedia/pakshas/';
  static const String encyclopediaPanchangLimbs =
      '${panchangCalenderBase}encyclopedia/panchang-limbs/';
  static const String encyclopediaMoonSigns =
      '${panchangCalenderBase}encyclopedia/moon-signs/';
  static const String encyclopediaAuspiciousTimings =
      '${panchangCalenderBase}encyclopedia/auspicious-timings/';
  static const String encyclopediaInauspiciousTimings =
      '${panchangCalenderBase}encyclopedia/inauspicious-timings/';
  static const String encyclopediaPlanets =
      '${panchangCalenderBase}encyclopedia/planets/';
  static const String encyclopediaChoghadiyaTypes =
      '${panchangCalenderBase}encyclopedia/choghadiya-types/';
  static const String panchangPresetLocations =
      '${panchangCalenderBase}preset-locations/';
  static const String panchangGuidanceOptions =
      '${panchangCalenderBase}guidance/options/';

  // Agent content endpoints (admin-configurable AI tools, prompts, content)
  static const String agentToolsEndpoint = '/api/ai/agent-tools/';
  static const String suggestedPromptsEndpoint =
      '/api/ai/suggested-prompts/';
  static const String contentBlocksEndpoint = '/api/ai/content-blocks/';
  static const String biomarkerDefinitionsEndpoint =
      '/api/ai/biomarker-definitions/';

  // AI & Health Profile endpoints (Django ai_service app)
  static const String healthProfileEndpoint = '/api/ai/health-profile/';
  static const String healthProfileBodyTypeEndpoint =
      '/api/ai/health-profile/body-type/';
  static const String healthProfileSummaryEndpoint =
      '/api/ai/health-profile/summary/';
  static const String healthProfileBirthDetailsEndpoint =
      '/api/ai/health-profile/birth-details/';
  static const String healthProfileGenerateSummaryDocEndpoint =
      '/api/ai/health-profile/generate-summary-doc/';
  static const String foodThaliEndpoint = '/api/ai/food-thali/';
  static const String medicalReportsEndpoint = '/api/ai/medical-reports/';
  static const String medicalMarkersEndpoint = '/api/ai/medical-markers/';
  static const String userTierQuotaEndpoint = '/api/ai/user-tier-quota/';
  static const String chatSessionsEndpoint = '/api/ai/chat-sessions/';

  // Ayurveda clinical assessment endpoints
  static const String ayurvedaQuestionsEndpoint = '/api/ayurveda/questions/';
  static const String ayurvedaSubmitQuizEndpoint = '/api/ayurveda/submit/';
  static const String ayurvedaReportEndpoint = '/api/ayurveda/report/';
  static const String ayurvedaAnswersEndpoint = '/api/ayurveda/answers/';


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

  // Payment endpoints (gateway-agnostic, currently backed by Easebuzz)
  static const String paymentStatusEndpoint = '/api/payments/status/';
  static const String paymentInitiateEndpoint = '/api/payments/initiate/';

  /// Easebuzz callback paths used by WebViewPage to detect payment completion.
  static const String easebuzzSuccessCallback =
      '/api/payments/easebuzz/callback/success/';
  static const String easebuzzFailureCallback =
      '/api/payments/easebuzz/callback/failure/';

  // Legal endpoints
  static const String legalEndpoint = '/api/core/legal/latest/';

  // Referral reward endpoints
  static const String referralRewardCountEndpoint =
      '/api/auth/referral_reward_count/';
  static const String referralsEndpoint = '/api/auth/referrals/';

  // User summary endpoint
  static const String userSummaryEndpoint = '/api/core/user-summary/';

  // AI Service (FastAPI) base URL — separate from the main Django backend
  static String get aiServiceBaseUrl =>
      dotenv.env['AI_SERVICE_BASE_URL'] ?? 'http://127.0.0.1:8001';

  // AI Agent Chat endpoints (relative to aiServiceBaseUrl)
  static const String aiChatEndpoint = '/api/v1/agent/chat';
  static const String aiChatStreamEndpoint = '/api/v1/agent/chat/stream';
  static const String aiSessionsEndpoint = '/api/v1/agent/sessions';
  static const String aiMemoryEndpoint = '/api/v1/agent/memory';

  // Headers
  static Map<String, String> getBaseHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  static Map<String, String> getAuthHeaders(String token) {
    return {...getBaseHeaders(), 'Authorization': 'Bearer $token'};
  }
}
