import 'package:get_it/get_it.dart';
import 'package:grocery_app/services/api_client.dart';
import 'package:grocery_app/services/payment_client.dart';
import 'package:grocery_app/services/product_service.dart';
import 'package:grocery_app/services/token_service.dart';
import 'package:grocery_app/services/oauth_service.dart';
import 'package:grocery_app/services/profile_service.dart';
import 'package:grocery_app/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:grocery_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:grocery_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:grocery_app/features/cart/domain/usecases/get_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/add_to_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/update_cart_item_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/remove_from_cart_use_case.dart';
import 'package:grocery_app/features/cart/domain/usecases/clear_cart_use_case.dart';
import 'package:grocery_app/services/panchang_service.dart';
import 'package:grocery_app/services/location_service.dart';
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/services/legal_service.dart';
import 'package:grocery_app/services/referral_reward_service.dart';
import 'package:grocery_app/services/rfp_services.dart';
import 'package:grocery_app/services/user_summary_service.dart';

import 'package:grocery_app/services/connectivity_service.dart';
import 'package:grocery_app/services/navigation_service.dart';

import 'package:grocery_app/features/misc/data/datasources/account_remote_data_source.dart';
import 'package:grocery_app/features/misc/data/repositories/account_repository_impl.dart';
import 'package:grocery_app/features/misc/domain/repositories/account_repository.dart';
import 'package:grocery_app/features/misc/domain/usecases/fetch_user_summary_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/sync_user_profile_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/account_cubit.dart';

import 'package:grocery_app/features/misc/data/datasources/help_remote_data_source.dart';
import 'package:grocery_app/features/misc/data/repositories/help_repository_impl.dart';
import 'package:grocery_app/features/misc/domain/repositories/help_repository.dart';
import 'package:grocery_app/features/misc/domain/usecases/send_otp_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/verify_otp_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/help_deactivate_account_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/help_confirm_deactivation_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/help_cubit.dart';

import 'package:grocery_app/features/misc/data/datasources/address_remote_data_source.dart';
import 'package:grocery_app/features/misc/data/repositories/address_repository_impl.dart';
import 'package:grocery_app/features/misc/domain/repositories/address_repository.dart';
import 'package:grocery_app/features/misc/domain/usecases/save_address_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/address_cubit.dart';

import 'package:grocery_app/features/misc/data/datasources/profile_remote_data_source.dart';
import 'package:grocery_app/features/misc/data/repositories/profile_repository_impl.dart';
import 'package:grocery_app/features/misc/domain/repositories/profile_repository.dart';
import 'package:grocery_app/features/misc/domain/usecases/update_user_profile_use_case.dart';
import 'package:grocery_app/features/misc/domain/usecases/upload_profile_image_use_case.dart';
import 'package:grocery_app/features/misc/presentation/cubit/profile_cubit.dart';

import 'package:grocery_app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:grocery_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:grocery_app/features/home/domain/repositories/home_repository.dart' as home_domain;
import 'package:grocery_app/features/home/domain/usecases/get_banners_use_case.dart';
import 'package:grocery_app/features/home/domain/usecases/get_communities_use_case.dart';
import 'package:grocery_app/features/home/presentation/cubit/home_cubit.dart';


import 'package:grocery_app/features/payments/data/datasources/easebuzz_remote_data_source.dart';
import 'package:grocery_app/features/payments/data/datasources/juspay_remote_data_source.dart';
import 'package:grocery_app/features/payments/data/repositories/easebuzz_payments_repository_impl.dart';
import 'package:grocery_app/features/payments/data/repositories/juspay_payments_repository_impl.dart';
import 'package:grocery_app/features/payments/domain/repositories/payments_repository.dart' as payments_domain;
import 'package:grocery_app/features/payments/domain/usecases/get_payment_status_use_case.dart';
import 'package:grocery_app/features/payments/domain/usecases/poll_payment_status_use_case.dart';
import 'package:grocery_app/features/payments/domain/usecases/verify_payment_response_use_case.dart';

import 'package:grocery_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:grocery_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:grocery_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:grocery_app/features/auth/domain/repositories/auth_repository.dart' as domain;
import 'package:grocery_app/features/auth/domain/usecases/check_auth_status_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/login_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/register_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/google_login_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/apple_login_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/logout_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/verify_token_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/update_profile_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/update_address_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/deactivate_account_use_case.dart';
import 'package:grocery_app/features/auth/domain/usecases/confirm_deactivation_use_case.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/orders/presentation/cubit/order_cubit.dart';
import 'package:grocery_app/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:grocery_app/features/notifications/presentation/cubit/notification_cubit.dart';

import 'package:grocery_app/features/products/data/datasources/products_remote_data_source.dart';
import 'package:grocery_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:grocery_app/features/products/domain/repositories/products_repository.dart' as prod_domain;
import 'package:grocery_app/features/products/domain/usecases/get_categories_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_featured_products_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_bestseller_products_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_products_by_category_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/get_product_by_id_use_case.dart';
import 'package:grocery_app/features/products/domain/usecases/search_products_use_case.dart';

import 'package:grocery_app/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:grocery_app/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:grocery_app/features/favorites/domain/repositories/favorites_repository.dart' as fav_domain;
import 'package:grocery_app/features/favorites/domain/usecases/get_favorites_use_case.dart';
import 'package:grocery_app/features/favorites/domain/usecases/toggle_favorite_use_case.dart';

import 'package:grocery_app/repositories/chat_repository.dart';

import 'package:grocery_app/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:grocery_app/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:grocery_app/features/orders/domain/repositories/orders_repository.dart' as orders_domain;
import 'package:grocery_app/features/orders/domain/usecases/get_orders_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_order_by_id_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/create_order_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/cancel_order_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/download_invoice_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_order_tracking_use_case.dart';
import 'package:grocery_app/features/orders/domain/usecases/get_user_shipping_details_use_case.dart';
import 'package:grocery_app/repositories/panchang_repository.dart';
import 'package:grocery_app/repositories/product_repository.dart';

import 'package:grocery_app/features/subscriptions/data/datasources/subscriptions_remote_data_source.dart';
import 'package:grocery_app/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:grocery_app/features/subscriptions/domain/repositories/subscriptions_repository.dart' as subs_domain;
import 'package:grocery_app/features/subscriptions/domain/usecases/get_user_subscriptions_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_details_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_plans_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/create_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/cancel_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/toggle_pause_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/repayment_subscription_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_invoices_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/get_subscription_plan_products_use_case.dart';
import 'package:grocery_app/features/subscriptions/domain/usecases/search_plans_for_variant_use_case.dart';

import 'package:grocery_app/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:grocery_app/features/notifications/data/datasources/notifications_local_data_source.dart';
import 'package:grocery_app/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:grocery_app/features/notifications/domain/repositories/notifications_repository.dart' as notif_domain;
import 'package:grocery_app/features/notifications/domain/usecases/get_local_notifications_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/get_unread_count_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/sync_notifications_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/mark_notifications_as_read_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/dismiss_notifications_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/register_device_token_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/unregister_device_token_use_case.dart';
import 'package:grocery_app/features/notifications/domain/usecases/reset_notification_badge_use_case.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  // Services
  getIt.registerLazySingleton<ApiClient>(() => ApiClient.create());
  getIt.registerLazySingleton<PaymentClient>(() => PaymentClient.create());
  getIt.registerLazySingleton<CategoryService>(() => CategoryService.create());
  getIt.registerLazySingleton<TokenService>(() => TokenService.create());
  getIt.registerLazySingleton<OAuthService>(() => OAuthService.create());
  getIt.registerLazySingleton<ProfileService>(() => ProfileService.create());

  getIt.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(tokenService: getIt<TokenService>()),
  );
  getIt.registerLazySingleton<PanchangService>(() => PanchangService.create());
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

  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService.create(),
  );
  getIt.registerLazySingleton<NavigationService>(
    () => NavigationService.create(),
  );

  getIt.registerLazySingleton<ProductRepository>(() => ProductRepository());
  getIt.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(getIt<CartRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetCartUseCase>(
    () => GetCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<AddToCartUseCase>(
    () => AddToCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<UpdateCartItemUseCase>(
    () => UpdateCartItemUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<RemoveFromCartUseCase>(
    () => RemoveFromCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerLazySingleton<ClearCartUseCase>(
    () => ClearCartUseCase(getIt<CartRepository>()),
  );

  getIt.registerLazySingleton<SubscriptionsRemoteDataSource>(
    () => SubscriptionsRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<subs_domain.SubscriptionsRepository>(
    () => SubscriptionsRepositoryImpl(getIt<SubscriptionsRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetUserSubscriptionsUseCase>(
    () => GetUserSubscriptionsUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<GetSubscriptionDetailsUseCase>(
    () => GetSubscriptionDetailsUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<GetSubscriptionPlansUseCase>(
    () => GetSubscriptionPlansUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<CreateSubscriptionUseCase>(
    () => CreateSubscriptionUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<CancelSubscriptionUseCase>(
    () => CancelSubscriptionUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<TogglePauseSubscriptionUseCase>(
    () => TogglePauseSubscriptionUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<RepaymentSubscriptionUseCase>(
    () => RepaymentSubscriptionUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<GetSubscriptionInvoicesUseCase>(
    () => GetSubscriptionInvoicesUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<GetSubscriptionPlanProductsUseCase>(
    () => GetSubscriptionPlanProductsUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );
  getIt.registerLazySingleton<SearchPlansForVariantUseCase>(
    () => SearchPlansForVariantUseCase(getIt<subs_domain.SubscriptionsRepository>()),
  );

  // Notifications Feature
  getIt.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<NotificationsLocalDataSource>(
    () => NotificationsLocalDataSourceImpl(),
  );
  getIt.registerLazySingleton<notif_domain.NotificationsRepository>(
    () => NotificationsRepositoryImpl(
      remoteDataSource: getIt<NotificationsRemoteDataSource>(),
      localDataSource: getIt<NotificationsLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<GetLocalNotificationsUseCase>(
    () => GetLocalNotificationsUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<GetUnreadCountUseCase>(
    () => GetUnreadCountUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<SyncNotificationsUseCase>(
    () => SyncNotificationsUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<MarkNotificationsAsReadUseCase>(
    () => MarkNotificationsAsReadUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<DismissNotificationsUseCase>(
    () => DismissNotificationsUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<RegisterDeviceTokenUseCase>(
    () => RegisterDeviceTokenUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<UnregisterDeviceTokenUseCase>(
    () => UnregisterDeviceTokenUseCase(getIt<notif_domain.NotificationsRepository>()),
  );
  getIt.registerLazySingleton<ResetNotificationBadgeUseCase>(
    () => ResetNotificationBadgeUseCase(getIt<notif_domain.NotificationsRepository>()),
  );

  // Home Feature
  getIt.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(),
  );
  getIt.registerLazySingleton<home_domain.HomeRepository>(
    () => HomeRepositoryImpl(getIt<HomeRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetBannersUseCase>(
    () => GetBannersUseCase(getIt<home_domain.HomeRepository>()),
  );
  getIt.registerLazySingleton<GetCommunitiesUseCase>(
    () => GetCommunitiesUseCase(getIt<home_domain.HomeRepository>()),
  );
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      getBannersUseCase: getIt<GetBannersUseCase>(),
      getCommunitiesUseCase: getIt<GetCommunitiesUseCase>(),
    ),
  );


  getIt.registerLazySingleton<ChatRepository>(() => ChatRepository());
  getIt.registerLazySingleton<PanchangRepository>(() => PanchangRepository());

  // New clean architecture Auth dependencies
  getIt.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());
  getIt.registerLazySingleton<domain.AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );

  // Usecases
  getIt.registerLazySingleton<CheckAuthStatusUseCase>(
    () => CheckAuthStatusUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<GoogleLoginUseCase>(
    () => GoogleLoginUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<AppleLoginUseCase>(
    () => AppleLoginUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<VerifyTokenUseCase>(
    () => VerifyTokenUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<UpdateAddressUseCase>(
    () => UpdateAddressUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<DeactivateAccountUseCase>(
    () => DeactivateAccountUseCase(getIt<domain.AuthRepository>()),
  );
  getIt.registerLazySingleton<ConfirmDeactivationUseCase>(
    () => ConfirmDeactivationUseCase(getIt<domain.AuthRepository>()),
  );

  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      checkAuthStatusUseCase: getIt<CheckAuthStatusUseCase>(),
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      googleLoginUseCase: getIt<GoogleLoginUseCase>(),
      appleLoginUseCase: getIt<AppleLoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      verifyTokenUseCase: getIt<VerifyTokenUseCase>(),
      updateProfileUseCase: getIt<UpdateProfileUseCase>(),
      updateAddressUseCase: getIt<UpdateAddressUseCase>(),
      deactivateAccountUseCase: getIt<DeactivateAccountUseCase>(),
      confirmDeactivationUseCase: getIt<ConfirmDeactivationUseCase>(),
    ),
  );

  // Payments Data Sources
  getIt.registerLazySingleton<JuspayRemoteDataSource>(() => JuspayRemoteDataSource());
  getIt.registerLazySingleton<EasebuzzRemoteDataSource>(() => EasebuzzRemoteDataSource());

  // Payments Repository (DI Factory)
  getIt.registerLazySingleton<payments_domain.PaymentsRepository>(() {
    const gatewayEnv = String.fromEnvironment('PAYMENT_GATEWAY', defaultValue: 'easebuzz');
    return createPaymentsRepository(gatewayEnv);
  });

  // Payments Use Cases
  getIt.registerLazySingleton<GetPaymentStatusUseCase>(
    () => GetPaymentStatusUseCase(getIt<payments_domain.PaymentsRepository>()),
  );
  getIt.registerLazySingleton<PollPaymentStatusUseCase>(
    () => PollPaymentStatusUseCase(getIt<payments_domain.PaymentsRepository>()),
  );
  getIt.registerLazySingleton<VerifyPaymentResponseUseCase>(
    () => VerifyPaymentResponseUseCase(getIt<payments_domain.PaymentsRepository>()),
  );

  // Products Clean Architecture dependencies
  getIt.registerLazySingleton<ProductsRemoteDataSource>(
    () => ProductsRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<prod_domain.ProductsRepository>(
    () => ProductsRepositoryImpl(getIt<ProductsRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(getIt<prod_domain.ProductsRepository>()),
  );
  getIt.registerLazySingleton<GetFeaturedProductsUseCase>(
    () => GetFeaturedProductsUseCase(getIt<prod_domain.ProductsRepository>()),
  );
  getIt.registerLazySingleton<GetBestsellerProductsUseCase>(
    () => GetBestsellerProductsUseCase(getIt<prod_domain.ProductsRepository>()),
  );
  getIt.registerLazySingleton<GetProductsByCategoryUseCase>(
    () => GetProductsByCategoryUseCase(getIt<prod_domain.ProductsRepository>()),
  );
  getIt.registerLazySingleton<GetProductByIdUseCase>(
    () => GetProductByIdUseCase(getIt<prod_domain.ProductsRepository>()),
  );
  getIt.registerLazySingleton<SearchProductsUseCase>(
    () => SearchProductsUseCase(getIt<prod_domain.ProductsRepository>()),
  );

  // Favorites Clean Architecture dependencies
  getIt.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<fav_domain.FavoritesRepository>(
    () => FavoritesRepositoryImpl(
      remoteDataSource: getIt<FavoritesRemoteDataSource>(),
      tokenService: getIt<TokenService>(),
    ),
  );
  getIt.registerLazySingleton<GetFavoritesUseCase>(
    () => GetFavoritesUseCase(getIt<fav_domain.FavoritesRepository>()),
  );
  getIt.registerLazySingleton<ToggleFavoriteUseCase>(
    () => ToggleFavoriteUseCase(getIt<fav_domain.FavoritesRepository>()),
  );

  // Orders Clean Architecture dependencies
  getIt.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<orders_domain.OrdersRepository>(
    () => OrdersRepositoryImpl(
      remoteDataSource: getIt<OrdersRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<GetOrdersUseCase>(
    () => GetOrdersUseCase(getIt<orders_domain.OrdersRepository>()),
  );
  getIt.registerLazySingleton<GetOrderByIdUseCase>(
    () => GetOrderByIdUseCase(getIt<orders_domain.OrdersRepository>()),
  );
  getIt.registerLazySingleton<CreateOrderUseCase>(
    () => CreateOrderUseCase(
      getIt<orders_domain.OrdersRepository>(),
      getIt<payments_domain.PaymentsRepository>(),
    ),
  );
  getIt.registerLazySingleton<CancelOrderUseCase>(
    () => CancelOrderUseCase(getIt<orders_domain.OrdersRepository>()),
  );
  getIt.registerLazySingleton<DownloadInvoiceUseCase>(
    () => DownloadInvoiceUseCase(getIt<orders_domain.OrdersRepository>()),
  );
  getIt.registerLazySingleton<GetOrderTrackingUseCase>(
    () => GetOrderTrackingUseCase(getIt<orders_domain.OrdersRepository>()),
  );
  getIt.registerLazySingleton<GetUserShippingDetailsUseCase>(
    () => GetUserShippingDetailsUseCase(getIt<orders_domain.OrdersRepository>()),
  );

  // Cubit Factories
  getIt.registerFactory<CartCubit>(
    () => CartCubit(
      getCartUseCase: getIt<GetCartUseCase>(),
      addToCartUseCase: getIt<AddToCartUseCase>(),
      updateCartItemUseCase: getIt<UpdateCartItemUseCase>(),
      removeFromCartUseCase: getIt<RemoveFromCartUseCase>(),
      clearCartUseCase: getIt<ClearCartUseCase>(),
    ),
  );

  getIt.registerFactory<ProductCubit>(
    () => ProductCubit(
      getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
      getFeaturedProductsUseCase: getIt<GetFeaturedProductsUseCase>(),
      getBestsellerProductsUseCase: getIt<GetBestsellerProductsUseCase>(),
      getProductsByCategoryUseCase: getIt<GetProductsByCategoryUseCase>(),
      getProductByIdUseCase: getIt<GetProductByIdUseCase>(),
      searchProductsUseCase: getIt<SearchProductsUseCase>(),
    ),
  );

  getIt.registerFactory<FavoritesCubit>(
    () => FavoritesCubit(
      getFavoritesUseCase: getIt<GetFavoritesUseCase>(),
      toggleFavoriteUseCase: getIt<ToggleFavoriteUseCase>(),
    ),
  );

  getIt.registerFactory<OrderCubit>(
    () => OrderCubit(
      getOrdersUseCase: getIt<GetOrdersUseCase>(),
      getOrderByIdUseCase: getIt<GetOrderByIdUseCase>(),
      createOrderUseCase: getIt<CreateOrderUseCase>(),
      cancelOrderUseCase: getIt<CancelOrderUseCase>(),
      downloadInvoiceUseCase: getIt<DownloadInvoiceUseCase>(),
    ),
  );

  getIt.registerFactory<SubscriptionCubit>(
    () => SubscriptionCubit(
      getUserSubscriptions: getIt<GetUserSubscriptionsUseCase>(),
      getSubscriptionDetails: getIt<GetSubscriptionDetailsUseCase>(),
      getSubscriptionPlans: getIt<GetSubscriptionPlansUseCase>(),
      createSubscription: getIt<CreateSubscriptionUseCase>(),
      cancelSubscription: getIt<CancelSubscriptionUseCase>(),
      togglePause: getIt<TogglePauseSubscriptionUseCase>(),
      repayment: getIt<RepaymentSubscriptionUseCase>(),
      getInvoices: getIt<GetSubscriptionInvoicesUseCase>(),
      getPlanProducts: getIt<GetSubscriptionPlanProductsUseCase>(),
      searchPlans: getIt<SearchPlansForVariantUseCase>(),
    ),
  );

  getIt.registerFactory<NotificationCubit>(
    () => NotificationCubit(
      getLocalNotificationsUseCase: getIt<GetLocalNotificationsUseCase>(),
      getUnreadCountUseCase: getIt<GetUnreadCountUseCase>(),
      syncNotificationsUseCase: getIt<SyncNotificationsUseCase>(),
      markNotificationsAsReadUseCase: getIt<MarkNotificationsAsReadUseCase>(),
      dismissNotificationsUseCase: getIt<DismissNotificationsUseCase>(),
      registerDeviceTokenUseCase: getIt<RegisterDeviceTokenUseCase>(),
      unregisterDeviceTokenUseCase: getIt<UnregisterDeviceTokenUseCase>(),
      resetNotificationBadgeUseCase: getIt<ResetNotificationBadgeUseCase>(),
    ),
  );

  // Misc Feature Stateful Dependencies & Cubits
  getIt.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(tokenService: getIt<TokenService>()),
  );
  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(remoteDataSource: getIt<AccountRemoteDataSource>()),
  );
  getIt.registerLazySingleton<FetchUserSummaryUseCase>(
    () => FetchUserSummaryUseCase(getIt<AccountRepository>()),
  );
  getIt.registerLazySingleton<SyncUserProfileUseCase>(
    () => SyncUserProfileUseCase(getIt<AccountRepository>()),
  );
  getIt.registerFactory<AccountCubit>(
    () => AccountCubit(
      fetchUserSummaryUseCase: getIt<FetchUserSummaryUseCase>(),
      syncUserProfileUseCase: getIt<SyncUserProfileUseCase>(),
    ),
  );

  getIt.registerLazySingleton<HelpRemoteDataSource>(
    () => HelpRemoteDataSourceImpl(profileService: getIt<ProfileService>()),
  );
  getIt.registerLazySingleton<HelpRepository>(
    () => HelpRepositoryImpl(remoteDataSource: getIt<HelpRemoteDataSource>()),
  );
  getIt.registerLazySingleton<SendOtpUseCase>(
    () => SendOtpUseCase(getIt<HelpRepository>()),
  );
  getIt.registerLazySingleton<VerifyOtpUseCase>(
    () => VerifyOtpUseCase(getIt<HelpRepository>()),
  );
  getIt.registerLazySingleton<HelpDeactivateAccountUseCase>(
    () => HelpDeactivateAccountUseCase(getIt<HelpRepository>()),
  );
  getIt.registerLazySingleton<HelpConfirmDeactivationUseCase>(
    () => HelpConfirmDeactivationUseCase(getIt<HelpRepository>()),
  );
  getIt.registerFactory<HelpCubit>(
    () => HelpCubit(
      sendOtpUseCase: getIt<SendOtpUseCase>(),
      verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
      deactivateAccountUseCase: getIt<HelpDeactivateAccountUseCase>(),
      confirmDeactivationUseCase: getIt<HelpConfirmDeactivationUseCase>(),
    ),
  );

  getIt.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSourceImpl(profileService: getIt<ProfileService>()),
  );
  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(remoteDataSource: getIt<AddressRemoteDataSource>()),
  );
  getIt.registerLazySingleton<SaveAddressUseCase>(
    () => SaveAddressUseCase(getIt<AddressRepository>()),
  );
  getIt.registerFactory<AddressCubit>(
    () => AddressCubit(saveAddressUseCase: getIt<SaveAddressUseCase>()),
  );

  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(profileService: getIt<ProfileService>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: getIt<ProfileRemoteDataSource>()),
  );
  getIt.registerLazySingleton<UpdateUserProfileUseCase>(
    () => UpdateUserProfileUseCase(getIt<ProfileRepository>()),
  );
  getIt.registerLazySingleton<UploadProfileImageUseCase>(
    () => UploadProfileImageUseCase(getIt<ProfileRepository>()),
  );
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      updateUserProfileUseCase: getIt<UpdateUserProfileUseCase>(),
      uploadProfileImageUseCase: getIt<UploadProfileImageUseCase>(),
    ),
  );
}

payments_domain.PaymentsRepository createPaymentsRepository(String gateway) {
  if (gateway.toLowerCase() == 'juspay') {
    return JuspayPaymentsRepositoryImpl(
      remoteDataSource: getIt<JuspayRemoteDataSource>(),
    );
  } else {
    return EasebuzzPaymentsRepositoryImpl(
      remoteDataSource: getIt<EasebuzzRemoteDataSource>(),
    );
  }
}

