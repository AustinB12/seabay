import 'package:flutter/material.dart';
import 'package:seabay_app/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ajjecosmnppnvwopgpax.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqamVjb3NtbnBwbnZ3b3BncGF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE5NjQ4MTgsImV4cCI6MjA1NzU0MDgxOH0.3z5wxn1clsaJkIl2iDFIrct6lFVh-H0dSqu8c-1GLmU',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seabay',
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define the default brightness and colors.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}
