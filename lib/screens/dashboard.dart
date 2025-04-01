import 'package:flutter/material.dart';
import 'package:seabay_app/auth/auth.dart';
import 'login.dart';
import 'homepage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final auth = AuthService();

  void _logout(BuildContext context) {
    auth.signOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    void goToHome() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Dashboard!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => goToHome(),
              child: const Text('Go to Home Page'),
            ),
          ],
        ),
      ),
    );
  }
}
