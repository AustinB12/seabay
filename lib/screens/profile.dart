import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart' as db_service;
import 'package:seabay_app/auth/auth.dart' as auth_service;
import 'login.dart';
import 'homepage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final db = db_service.DbService();
  final auth = auth_service.AuthService();
  bool isEditing = false;
  Future<db_service.SeabayUser?>? _profile;

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false);
  }

  void _goToHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  void initState() {
    _profile = db.getCurrentUserProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final usersEmail = auth.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
          IconButton(
              onPressed: () => setState(() {
                    isEditing = !isEditing;
                  }),
              icon: const Icon(Icons.edit)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Welcome to your profile!!'),
            Text(usersEmail ?? 'Email not found'),
            Builder(
                builder: (BuildContext builder) =>
                    isEditing ? Text('Editing') : Text('Not editing')),
            FutureBuilder<db_service.SeabayUser?>(
                future: _profile,
                builder: (BuildContext context,
                    AsyncSnapshot<db_service.SeabayUser?> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Text(
                        '${snapshot.data?.firstName} ${snapshot.data?.lastName}');
                  } else {
                    return CircularProgressIndicator();
                  }
                }),
            Padding(
              padding: EdgeInsets.all(40),
              child: ElevatedButton(
                onPressed: () => _goToHome(context),
                child: const Text('Go to Home Page'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
