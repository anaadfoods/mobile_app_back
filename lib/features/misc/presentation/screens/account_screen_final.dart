import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:grocery_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:grocery_app/common_widgets/loading_state_widget.dart';
import 'package:grocery_app/features/misc/presentation/screens/account_screen.dart';
import 'package:grocery_app/features/auth/presentation/screens/login_screen.dart';

class AccountScreenFinal extends StatelessWidget {
  const AccountScreenFinal({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to listen to the AuthCubit's state changes.
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Based on the state, decide which screen to show.
        if (state is Authenticated) {
          // If the user is logged in, show the main account screen.
          return const AccountScreen();
        } else if (state is AuthInitial) {
          // Preserve the screen layout while initial session check is running on app launch.
          return const Scaffold(
            body: SafeArea(
              child: LoadingStateWidget(itemCount: 3, itemHeight: 84),
            ),
          );
        } else {
          // For Unauthenticated, AuthLoading (submitting credentials), and AuthError,
          // keep LoginScreen mounted so inputs, animations, and snackbar listeners are preserved.
          return const LoginScreen();
        }
      },
    );
  }
}
