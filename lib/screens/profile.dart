import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/auth/auth.dart';
import 'login.dart';
import 'homepage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final db = DbService();
  final auth = AuthService();
  bool isEditing = false;
  late Future<SeabayUser> _profile;

  final firstNameController = TextEditingController();

  final lastNameController = TextEditingController();

  void _logout(BuildContext context) {
    auth.signOut();
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

  void editProfile() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Edit Profile'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('First Name'),
                  TextField(
                    controller: firstNameController,
                  ),
                  const Text('Last Name'),
                  TextField(controller: lastNameController),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      firstNameController.clear();
                      lastNameController.clear();
                    },
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      db.updateUserProfile(SeabayUser(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                      ));
                    },
                    child: const Text('Save')),
              ],
            ));
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
                onPressed: () => _goToHome(context),
                icon: const Icon(Icons.home),
                tooltip: 'Go to homepage'),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () => editProfile(), child: const Icon(Icons.edit)),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<SeabayUser>(
                future: _profile,
                builder: (builder, AsyncSnapshot<SeabayUser> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                            text: TextSpan(
                                text: 'First Name:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text('${snapshot.data?.firstName}'),
                        RichText(
                            text: TextSpan(
                                text: 'Last Name:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text('${snapshot.data?.lastName}'),
                        RichText(
                            text: TextSpan(
                                text: 'Email:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(usersEmail as String),
                      ],
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                }),
          ],
        ))

        // Center(
        //   child: Column(
        //     mainAxisAlignment: MainAxisAlignment.start,
        //     children: [
        //       const Text('Welcome to your profile!!'),
        //       Text(usersEmail ?? 'Email not found'),
        //       Builder(
        //           builder: (BuildContext builder) =>
        //               isEditing ? Text('Editing') : Text('Not editing')),
        //       FutureBuilder<SeabayUser?>(
        //           future: _profile,
        //           builder: (BuildContext context,
        //               AsyncSnapshot<SeabayUser?> snapshot) {
        //             if (snapshot.connectionState == ConnectionState.done) {
        //               return Text(
        //                   '${snapshot.data?.firstName} ${snapshot.data?.lastName}');
        //             } else {
        //               return CircularProgressIndicator();
        //             }
        //           }),
        //       Padding(
        //         padding: EdgeInsets.all(40),
        //         child: ElevatedButton(
        //           onPressed: () => _goToHome(context),
        //           child: const Text('Go to Home Page'),
        //         ),
        //       )
        //     ],
        //   ),
        // ),
        );
  }
}
