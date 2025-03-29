import 'package:flutter/material.dart';
import 'login.dart';
import 'homepage.dart';


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});


  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
  }
  void _goToHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }
  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _goToHome(context),
              child: const Text('Go to Home Page'),
            ),
          ],
        ),
      ),
    );
  }
}

