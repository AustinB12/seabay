import 'package:flutter/material.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/screens/homepage.dart';
import 'package:seabay_app/screens/login.dart';
import 'package:seabay_app/api/db_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => CreateAccountPageState();
}

class CreateAccountPageState extends State<CreateAccountPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  String errorMessage = '';

  final authService = AuthService();

  Future<void> _createNewAccount() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    String? newUserId;

    try {
      newUserId = await authService.signUpWithEmailPassword(email, password);
    } catch (e) {
      setState(() {
        // errorMessage =
        //     'Account creation failed. Please try again. ${e.toString()}';
        errorMessage =
            'Account creation failed. Please try again.';
      });
    }
    if (newUserId != null) {
      await authService.createNewUserProfile(
        authId: newUserId,
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );
      await DbService().createDefaultWishlist(newUserId);
      _goToHome();
    }
  }

  String? validateEmail(String? value) {
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value ?? '');

    return emailValid ? null : "Email address is not valid.";
  }

  String? validateName(String? value){
    if (value == null || value.isEmpty){
      return 'Fill in first or last name.';
    }
    final reg = RegExp(r'^[a-zA-Z]+$');
    if (!reg.hasMatch(value)){
      return 'Names can only include letters.';
    }
    return null;
  }

  void _goToHome() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void _goToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => validateName(value),
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => validateName(value),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (String? value) {
                    return validateEmail(value);
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
                  validator: (value) =>
                      passwordController.text == confirmPasswordController.text
                          ? null
                          : 'Passwords must match',
                ),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(errorMessage, style: const TextStyle(color: Colors.red)),
                ],
                ElevatedButton(
                  onPressed: () => _createNewAccount(),
                  child: const Text('Create Account'),
                ),
                ElevatedButton(
                  onPressed: () => _goToLoginPage(),
                  child: const Text('Back'),
                ),
              ],
            ),
          )),
    );
  }
}
