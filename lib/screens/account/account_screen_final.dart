import "package:grocery_app/common_widgets/global_import.dart";

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
        } else if (state is Unauthenticated || state is AuthError) {
          // If the user is logged out or there's an error, show the login/signup prompt.
          return const AuthScreen();
        } else {
          // During initial loading or any other transient state, show a loading indicator.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
