import 'package:flutter/material.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/screens/create_account.dart';
import 'package:seabay_app/screens/dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String errorMessage = '';

  final authService = AuthService();

  void _goToCreateAccountPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CreateAccountPage()),
    );
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      final response = await authService.signInWithEmailPassword(email, password);

      if (response.user == null) {
        setState(() {
          errorMessage = 'Login failed. Please try again.';
        });
        return;
      }
      if (response.user != null) {
        // User is logged in successfully
        final userId = response.user?.id;
        authService.createNewUserProfile(userId!);
      } else {
        setState(() {
          errorMessage = 'Login failed. Please try again.';
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed. Please try again. ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onSubmitted: (value) {
                  _login();
                }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ],
            ElevatedButton(
              onPressed: () => _goToCreateAccountPage(context),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
