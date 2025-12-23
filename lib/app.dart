import 'package:grocery_app/common_widgets/global_import.dart';
import 'package:grocery_app/cubits/chats/chat_cubit.dart';
import 'package:grocery_app/repositories/chat_repository.dart';

import 'package:grocery_app/screens/welcome_screen.dart';

import 'package:grocery_app/styles/theme.dart';

class MyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const MyApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => ProductRepository()),
        RepositoryProvider(create: (_) => CartRepository()),
        RepositoryProvider(create: (context) => OrderRepository()),
        RepositoryProvider(create: (context) => SubscriptionRepository()),
        RepositoryProvider(create: (context) => FavoritesRepository()),
        RepositoryProvider(create: (context) => NotificationRepository()),
        RepositoryProvider(create: (context) => ChatRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create: (context) => AuthCubit(
              authRepository: context.read<AuthRepository>(),
            )..checkAuthStatus(),
          ),
          BlocProvider(
            create: (context) => ProductCubit(
              productRepository: context.read<ProductRepository>(),
            )..loadHomePageData(),
          ),
          BlocProvider(
            create: (context) => NotificationCubit(
              notificationRepository: context.read<NotificationRepository>(),
            ),
          ),
         BlocProvider(
        create: (context) => ChatCubit(
          repository: context.read<ChatRepository>(),
        ),),
BlocProvider<CartCubit>(
        create: (context) => CartCubit(context.read<CartRepository>()),
      ),
          BlocProvider(create: (context) => OrderCubit(orderRepository: context.read<OrderRepository>())),
          BlocProvider(create: (context) => SubscriptionCubit(subscriptionRepository: context.read<SubscriptionRepository>())),
          BlocProvider(create: (context) => FavoritesCubit(favoritesRepository: context.read<FavoritesRepository>())),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              navigatorKey: NavigationService().navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              builder: (context, child) {
                // The DoubleBackToExitApp now correctly wraps the navigator's child
                return DoubleBackToExitApp(child: child!);
              },
              // **FIX 1**: Pass hasSeenWelcome to the AppInitializer
              home: AppInitializer(hasSeenWelcome: hasSeenWelcome),
              onGenerateRoute: (settings) {
                if (settings.name?.startsWith('flutterpay://') == true) {
                  final uri = Uri.parse(settings.name!);
                  if (uri.path.contains('payment/success')) {
                    return MaterialPageRoute(
                      builder: (context) => OrderAcceptedScreen(
                        paymentStatus: null,
                        isSubscription: false,
                      ),
                    );
                  }
                }
                return null;
              },
              
            );
          },
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  // **FIX 2**: Accept the hasSeenWelcome flag
  final bool hasSeenWelcome;
  const AppInitializer({super.key, required this.hasSeenWelcome});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure context is fully available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService().initialize(context.read<NotificationCubit>());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // **FIX 3**: Pass the hasSeenWelcome flag down to the AuthWrapper
    return AuthWrapper(hasSeenWelcome: widget.hasSeenWelcome);
  }
}

class AuthWrapper extends StatelessWidget {
  // **FIX 4**: Accept the hasSeenWelcome flag
  final bool hasSeenWelcome;
  const AuthWrapper({super.key, required this.hasSeenWelcome});

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
              // Your navigation logic here
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return const DashboardScreen();
          } else if (state is Unauthenticated || state is AuthError) {
            // **FIX 5**: Use the passed-in flag to make the decision
            if (hasSeenWelcome == false) {
              return const WelcomeScreen();
            } else {
              return const LoginScreen();
            }
          } else {
            // AuthInitial or AuthLoading
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}