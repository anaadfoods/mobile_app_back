import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:device_preview/device_preview.dart';

// Feature Cubits
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:grocery_app/features/products/presentation/cubit/product_cubit.dart';
import 'package:grocery_app/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:grocery_app/features/orders/presentation/cubit/order_cubit.dart';
import 'package:grocery_app/features/subscriptions/presentation/cubit/subscription_cubit.dart';
import 'package:grocery_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:grocery_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:grocery_app/core/theme/cubit/theme_cubit.dart';

// Services & Helpers
import 'package:grocery_app/services/notification_service.dart';
import 'package:grocery_app/helpers/double_click_back.dart';
import 'package:grocery_app/core/theme/app_theme.dart';
import 'package:grocery_app/common_widgets/connectivity_wrapper.dart';
import 'package:grocery_app/routes/app_router.dart';
import 'package:grocery_app/service_locator.dart';

class MyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const MyApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit()),
        BlocProvider(
          create: (context) => getIt<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) => getIt<ProductCubit>()..loadHomePageData(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => getIt<CartCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<OrderCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<SubscriptionCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<FavoritesCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<NotificationCubit>(),
        ),
        BlocProvider(
          create: (context) => getIt<HomeCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            scrollBehavior: const ScrollBehavior().copyWith(
              physics: const ClampingScrollPhysics(),
            ),
            debugShowCheckedModeBanner: false,
            useInheritedMediaQuery: true,
            locale: kDebugMode ? DevicePreview.locale(context) : null,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRouter().router,
            builder: (context, child) {
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

              final wrappedWidget = AppGlobalListeners(child: widget);

              return kDebugMode
                  ? DevicePreview.appBuilder(context, wrappedWidget)
                  : wrappedWidget;
            },
          );
        },
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final notificationService = getIt<NotificationService>();
        notificationService.initialize(context.read<NotificationCubit>());
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
              context.read<NotificationCubit>().syncNotifications();
            } else if (state is Unauthenticated) {
              context.read<NotificationCubit>().unregisterDevice();
              context.read<CartCubit>().clearCartState();
              context.read<FavoritesCubit>().clearFavoritesState();
              context.read<OrderCubit>().clearOrders();
              context.read<SubscriptionCubit>().clearSubscriptionState();
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}
