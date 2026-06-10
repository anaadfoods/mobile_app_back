import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:device_preview/device_preview.dart';

// Cubits
import 'package:grocery_app/cubits/auth/auth_cubit.dart';
import 'package:grocery_app/cubits/auth/auth_state.dart';
import 'package:grocery_app/cubits/cart/cart_cubit.dart';
import 'package:grocery_app/cubits/product/product_cubit.dart';
import 'package:grocery_app/cubits/favorites/favorites_cubit.dart';
import 'package:grocery_app/cubits/order/order_cubit.dart';
import 'package:grocery_app/cubits/subscription/subscription_cubit.dart';
import 'package:grocery_app/logic/cubits/chat_cubit.dart';
import 'package:grocery_app/cubits/notification/notification_cubit.dart';
import 'package:grocery_app/cubits/notification/notification_state.dart';
import 'package:grocery_app/cubits/theme/theme_cubit.dart';

// Repositories
import 'package:grocery_app/repositories/auth_repository.dart';
import 'package:grocery_app/repositories/cart_repository.dart';
import 'package:grocery_app/repositories/product_repository.dart';
import 'package:grocery_app/repositories/favorites_repository.dart';
import 'package:grocery_app/repositories/order_repository.dart';
import 'package:grocery_app/repositories/subscription_repository.dart';
import 'package:grocery_app/repositories/chat_repository.dart';
import 'package:grocery_app/repositories/notification_repository.dart';

// Screens
// import 'package:grocery_app/screens/dashboard/dashboard_screen.dart'; // Handled by Router
// import 'package:grocery_app/screens/auth/login_screen.dart'; // Handled by Router
// import 'package:grocery_app/screens/welcome_screen.dart'; // Handled by Router
// import 'package:grocery_app/screens/order_accepted_screen.dart'; // Unused

// Services
import 'package:grocery_app/services/notification_service.dart';
// import 'package:grocery_app/services/navigation_service.dart'; // Unused
import 'package:grocery_app/helpers/double_click_back.dart';
import 'package:grocery_app/core/theme/app_theme.dart';

import 'package:grocery_app/common_widgets/connectivity_wrapper.dart';
import 'package:grocery_app/routes/app_router.dart';

import 'package:grocery_app/services/notification_sync_manager.dart';

import 'package:grocery_app/service_locator.dart';

class MyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const MyApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => getIt<AuthRepository>()),
        RepositoryProvider(create: (context) => getIt<ProductRepository>()),
        RepositoryProvider(create: (_) => getIt<CartRepository>()),
        RepositoryProvider(create: (context) => getIt<OrderRepository>()),
        RepositoryProvider(
          create: (context) => getIt<SubscriptionRepository>(),
        ),
        RepositoryProvider(create: (context) => getIt<FavoritesRepository>()),
        RepositoryProvider(
          create: (context) => getIt<NotificationRepository>(),
        ),
        RepositoryProvider(create: (context) => getIt<ChatRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create:
                (context) =>
                    AuthCubit(authRepository: context.read<AuthRepository>())
                      ..checkAuthStatus(),
          ),
          BlocProvider(
            create:
                (context) => ProductCubit(
                  productRepository: context.read<ProductRepository>(),
                )..loadHomePageData(),
          ),
          BlocProvider<CartCubit>(
            create: (context) => CartCubit(context.read<CartRepository>()),
          ),
          BlocProvider(
            create:
                (context) => OrderCubit(
                  orderRepository: context.read<OrderRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => SubscriptionCubit(
                  subscriptionRepository:
                      context.read<SubscriptionRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => FavoritesCubit(
                  favoritesRepository: context.read<FavoritesRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) => NotificationCubit(
                  notificationRepository:
                      context.read<NotificationRepository>(),
                ),
          ),
          BlocProvider(
            create:
                (context) =>
                    ChatCubit(repository: context.read<ChatRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              scrollBehavior: const ScrollBehavior().copyWith(
                physics: const ClampingScrollPhysics(),
              ),
              // navigatorKey is now in AppRouter
              debugShowCheckedModeBanner: false,
              useInheritedMediaQuery: true,
              locale: kDebugMode ? DevicePreview.locale(context) : null,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: AppRouter().router,
              builder: (context, child) {
                // Prevent app from using system font size settings
                final widget = MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.textScalerOf(
                        context,
                      ).scale(1.0).clamp(0.85, 1.3),
                    ),
                  ),
                  child: ConnectivityWrapper(
                    child: DoubleBackToExitApp(child: child!),
                  ),
                );

                // Wrap with AppGlobalListeners to handle init and bloc listeners
                final wrappedWidget = AppGlobalListeners(child: widget);

                return kDebugMode
                    ? DevicePreview.appBuilder(context, wrappedWidget)
                    : wrappedWidget;
              },
            );
          },
        ),
      ),
    );
  }
}

class AppGlobalListeners extends StatefulWidget {
  final Widget child;
  const AppGlobalListeners({super.key, required this.child});

  @override
  State<AppGlobalListeners> createState() => _AppGlobalListenersState();
}

class _AppGlobalListenersState extends State<AppGlobalListeners>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notificationService = getIt<NotificationService>();
        notificationService.initialize(context.read<NotificationCubit>());

        // Process any pending initial notification now that context/navigator is ready
        notificationService.processInitialMessage();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AuthCubit>().verifyAndRefreshToken();
      getIt<NotificationSyncManager>().flushPendingQueue();
      getIt<NotificationSyncManager>().syncWithBackend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              context.read<NotificationCubit>().registerDevice();
              context.read<CartCubit>().loadCart();
              context.read<OrderCubit>().fetchOrders();
              context.read<SubscriptionCubit>().fetchUserSubscriptions();
              context.read<FavoritesCubit>().loadFavorites();

              // Trigger sync on authentication
              getIt<NotificationSyncManager>().flushPendingQueue();
              getIt<NotificationSyncManager>().syncWithBackend();
            } else if (state is Unauthenticated) {
              context.read<NotificationCubit>().unregisterDevice();
              context.read<CartCubit>().clearCart();
              context.read<FavoritesCubit>().clearFavoritesState();
            }
          },
        ),
        BlocListener<NotificationCubit, NotificationState>(
          listener: (context, state) {
            if (state is NavigateToRoute) {
              // NotificationCubit's navigation logic might need review if it uses Navigator directly
              // If it uses NavigationService, it should key into GoRouter's navigator
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}
