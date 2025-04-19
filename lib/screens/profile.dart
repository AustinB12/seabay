import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/types.dart';
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
  late Future<List<WishList>> _wishlists;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final wlNameController = TextEditingController();
  final wlDescController = TextEditingController();

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
                  TextField(
                    controller: lastNameController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await auth.updateUserProfile(SeabayUser(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                    ));
                    setState(() {
                      _profile = auth.getCurrentUserProfile();
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ));
  }

  void deleteWishlistConfirmation(WishList wl) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: Text("Delete ${wl.name} Wishlist?"),
                content: const Text("This cannot be undone."),
                actions: [
                  IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await deleteWishlist(wl.id);
                      setState(() {
                        _wishlists = db.getWishlists();
                      });
                    },
                    icon: Icon(Icons.check),
                    tooltip: 'Confirm',
                  ),
                  IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                    tooltip: 'Cancel',
                  ),
                ]));
  }

  Future<void> deleteWishlist(int id) async {
    await db.deleteWishlistById(id);
  }

  void addWishlist() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('New Wishlist'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Wishlist Name:'),
                  TextField(
                    controller: wlNameController,
                  ),
                  const Text('Wishlist Description:'),
                  TextField(
                    controller: wlDescController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await db.createWishlist(
                        wlNameController.text, wlDescController.text);
                    wlDescController.clear();
                    wlNameController.clear();
                    setState(() {
                      _wishlists = db.getWishlists();
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            ));
  }

  @override
  void initState() {
    _profile = auth.getCurrentUserProfile();
    _wishlists = db.getWishlists();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<SeabayUser>(
                future: _profile,
                builder: (builder, AsyncSnapshot<SeabayUser> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    lastNameController.text = snapshot.data?.lastName ?? '';
                    firstNameController.text = snapshot.data?.firstName ?? '';
                    return Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                            text: TextSpan(
                                text: 'First Name:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(firstNameController.text),
                        RichText(
                            text: TextSpan(
                                text: 'Last Name:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(lastNameController.text),
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
            RichText(
                text: TextSpan(
                    text: 'Wishlists:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white))),
            FutureBuilder<List<WishList>>(
                future: _wishlists,
                builder: (builder, AsyncSnapshot<List<WishList>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final wishlists = snapshot.data;

                    if (wishlists!.isEmpty) {
                      return const Text('No Wishlists Yet');
                    }
                    return Container(
                        height: 300,
                        child: ListView.builder(
                            itemCount: wishlists.length,
                            itemBuilder: (BuildContext context, int index) {
                              final wl = wishlists[index];
                              return ListTile(
                                  title: Text(wl.name),
                                  subtitle: Text(wl.description),
                                  trailing: SizedBox(
                                      width: 100,
                                      child: Row(children: [
                                        IconButton(
                                            onPressed: null,
                                            icon: Icon(Icons.add)),
                                        IconButton(
                                            onPressed: () =>
                                                deleteWishlistConfirmation(wl),
                                            icon: Icon(Icons.delete)),
                                      ])));
                            }));
                  } else {
                    return CircularProgressIndicator();
                  }
                }),
            ElevatedButton(
                onPressed: () => addWishlist(),
                child: const Text('Add Wishlist'))
          ],
        )
      )
    ));
  }
}
