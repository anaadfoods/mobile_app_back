import 'package:get_it/get_it.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/payment_client.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/services/oauth_service.dart';
import 'package:grocery_app/services/profile_service.dart';
import 'package:grocery_app/services/order_service.dart';
import 'package:grocery_app/services/subscription_service.dart';
import 'package:grocery_app/services/cart_service.dart';
import 'package:grocery_app/services/panchang_service.dart';
import 'package:grocery_app/services/banner_service.dart';
import 'package:grocery_app/services/location_service.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/services/legal_service.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/services/rfp_services.dart';
import 'package:grocery_app/services/user_summary_service.dart';
import 'package:grocery_app/services/favorite_state_service.dart';
import 'package:grocery_app/services/connectivity_service.dart';
import 'package:grocery_app/services/navigation_service.dart';
import 'package:grocery_app/services/payment_service.dart';
import 'package:grocery_app/services/notification_sync_manager.dart';

import 'package:grocery_app/repositories/auth_repository.dart';
import 'package:grocery_app/repositories/cart_repository.dart';
import 'package:grocery_app/repositories/chat_repository.dart';
import 'package:grocery_app/repositories/favorites_repository.dart';
import 'package:grocery_app/repositories/notification_repository.dart';
import 'package:grocery_app/repositories/order_repository.dart';
import 'package:grocery_app/repositories/panchang_repository.dart';
import 'package:grocery_app/repositories/product_repository.dart';
import 'package:grocery_app/repositories/subscription_repository.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  // Services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient.create());
  getIt.registerLazySingleton<PaymentClient>(() => PaymentClient.create());
  getIt.registerLazySingleton<CategoryService>(() => CategoryService.create());
  getIt.registerLazySingleton<TokenService>(() => TokenService.create());
  getIt.registerLazySingleton<OAuthService>(() => OAuthService.create());
  getIt.registerLazySingleton<ProfileService>(() => ProfileService.create());
  getIt.registerLazySingleton<OrderService>(() => OrderService.create());
  getIt.registerLazySingleton<PaymentService>(() => PaymentService.create());
  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService.create(),
  );
  getIt.registerLazySingleton<CartService>(() => CartService.create());
  getIt.registerLazySingleton<PanchangService>(() => PanchangService.create());
  getIt.registerLazySingleton<BannerService>(() => BannerService.create());
  getIt.registerLazySingleton<LocationService>(() => LocationService.create());
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService.create(),
  );
  getIt.registerLazySingleton<LegalService>(() => LegalService.create());
  getIt.registerLazySingleton<ReferralRewardService>(
    () => ReferralRewardService.create(),
  );
  getIt.registerLazySingleton<DeliveryService>(() => DeliveryService.create());
  getIt.registerLazySingleton<UserSummaryService>(
    () => UserSummaryService.create(),
  );
  getIt.registerLazySingleton<FavoriteStateService>(
    () => FavoriteStateService.create(),
  );
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService.create(),
  );
  getIt.registerLazySingleton<NavigationService>(
    () => NavigationService.create(),
  );
  getIt.registerLazySingleton<NotificationSyncManager>(
    () => NotificationSyncManager.create(),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository());
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepository());
  getIt.registerLazySingleton<CartRepository>(() => CartRepository());
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepository());
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepository(),
  );
  getIt.registerLazySingleton<FavoritesRepository>(() => FavoritesRepository());
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(),
  );
  getIt.registerLazySingleton<ChatRepository>(() => ChatRepository());
  getIt.registerLazySingleton<PanchangRepository>(() => PanchangRepository());
}
