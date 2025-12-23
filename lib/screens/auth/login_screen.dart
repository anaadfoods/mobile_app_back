import 'package:grocery_app/common_widgets/global_import.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  "assets/images/OnBoarding/background_login_sign.png",
                  fit: BoxFit.cover,
                ),
              ),

              // Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.all(AppColors.spacingXL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Image.asset(
                                    "assets/images/OnBoarding/logo.png",
                                    height: 70,
                                  ),
                                ),
                                const SizedBox(height: AppColors.spacingXXL),

                                // Login Card
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppColors.spacingXL,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.primary.withOpacity(0.9),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppColors.radiusXL,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Welcome Back!",
                                          style: textTheme.headlineSmall
                                              ?.copyWith(
                                                color: colorScheme.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(
                                          height: AppColors.spacingXS,
                                        ),
                                        Text(
                                          "Login to your account",
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onPrimary
                                                .withOpacity(0.85),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppColors.spacingXL,
                                        ),

                                        // Email Input
                                        CustomInput(
                                          hintText: "Email",
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          onPrimary: true,
                                          validator: (value) {
                                            if (value == null || value.isEmpty)
                                              return 'Please enter your email';
                                            if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            ).hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(
                                          height: AppColors.spacingL,
                                        ),

                                        // Password Input
                                        CustomInput(
                                          hintText: "Password",
                                          obscureText: true,
                                          controller: _passwordController,
                                          onPrimary: true,
                                          validator: (value) {
                                            if (value == null || value.isEmpty)
                                              return 'Please enter your password';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(
                                          height: AppColors.spacingXS,
                                        ),

                                        // Forgot Password
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed:
                                                isLoading
                                                    ? null
                                                    : () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_) =>
                                                                const ForgetPasswordScreen(),
                                                      ),
                                                    ),
                                            child: Text(
                                              "Forgot Password?",
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme.onPrimary
                                                        .withOpacity(0.85),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: AppColors.spacingM,
                                        ),

                                        // Login Button
                                        AppButton(
                                          label:
                                              isLoading
                                                  ? "Logging in..."
                                                  : "Login",
                                          fontWeight: FontWeight.bold,
                                          onPressed:
                                              isLoading ? null : _handleLogin,
                                        ),
                                        const SizedBox(
                                          height: AppColors.spacingL,
                                        ),

                                        // Register Link
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Don't have an account?",
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: colorScheme.onPrimary
                                                        .withOpacity(0.85),
                                                  ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  isLoading
                                                      ? null
                                                      : () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  const SignupScreen(),
                                                        ),
                                                      ),
                                              child: Text(
                                                "Register",
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.secondary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(color: theme.dividerColor),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppColors.spacingM,
                                      ),
                                      child: Text(
                                        "or continue with",
                                        style: textTheme.bodySmall?.copyWith(
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(color: theme.dividerColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppColors.spacingXL),

                                // Google Sign-in Button
                                Center(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colorScheme.onPrimary,
                                      side: BorderSide(
                                        color: colorScheme.onPrimary
                                            .withOpacity(0.7),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppColors.spacingXXL,
                                        vertical: AppColors.spacingM,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppColors.radiusRound,
                                        ),
                                      ),
                                    ),
                                    onPressed:
                                        isLoading
                                            ? null
                                            : () =>
                                                context
                                                    .read<AuthCubit>()
                                                    .googleLogin(),
                                    icon: const Icon(
                                      FontAwesomeIcons.google,
                                      size: 18,
                                    ),
                                    label: const Text("Sign in with Google"),
                                  ),
                                ),
                                const SizedBox(height: AppColors.spacingXL),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
