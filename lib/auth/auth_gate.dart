import 'package:flutter/material.dart';
import 'package:seabay_app/screens/homepage.dart';
import 'package:seabay_app/screens/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // LOADING
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // Check for valid session
          final session = snapshot.hasData ? snapshot.data!.session : null;

          if (session != null) {
            return HomePage();
          } else {
            return LoginPage();
          }
        });
  }
}
