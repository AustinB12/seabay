import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/types.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/components/profile_picture.dart';
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
  late Future<SeabayUser> _profile;
  late Future<List<WishList>> _wishlists;
  late Future<List<Post>> _wishlistPosts;
  late Future<List<Post>> _userPosts;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final wlNameController = TextEditingController();
  final wlDescController = TextEditingController();

  @override
  void initState() {
    _profile = auth.getCurrentUserProfile();
    _wishlistPosts = db.loadWishlistedPosts();
    _userPosts = db.getPostsByUser();
    _wishlists = db.getWishlists();
    super.initState();
  }

  void _logout(BuildContext context) {
    auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  Future<void> _refreshUserPosts() async {
  setState(() {
    _userPosts = db.getPostsByUser();
  });
}


  void _editPostDialog(Post post) {
  final titleController = TextEditingController(text: post.title);
  final descController = TextEditingController(text: post.description);
  final priceController = TextEditingController(text: post.price?.toString());

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Post'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final updatedPost = Post(
              id: post.id,
              title: titleController.text,
              description: descController.text,
              price: int.tryParse(priceController.text) ?? 0,
              isActive: post.isActive,
              userId: post.userId,
              imageUrls: post.imageUrls,
            );

            await db.updatePost(updatedPost);
            await _refreshUserPosts();
            Navigator.pop(context);
            setState(() {
              _wishlistPosts = db.loadWishlistedPosts();
              _userPosts = db.getPostsByUser(); // if you're using this section too
            });
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}


  void _editProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
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
      ),
    );
  }

  void _showPostDetails(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(post.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (post.description != null)
              Text(post.description!, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 10),
            Text('Price: \$${post.price}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _removeFromWishlist(int postId) async {
    await db.removePostIdFromWishlistJson(postId);
    setState(() {
      _wishlistPosts = db.loadWishlistedPosts();
    });
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
  Widget build(BuildContext context) {
    final usersEmail = auth.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => _goToHome(context),
            tooltip: 'Go to Home',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editProfileDialog,
        child: const Icon(Icons.edit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
        Padding(padding: EdgeInsets.all(16), child:
        Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            FutureBuilder<SeabayUser>(
                future: _profile,
                initialData: SeabayUser(
                    firstName: 'Loading...',
                    lastName: 'Loading...',
                    profilePictureUrl: null),
                builder: (builder, AsyncSnapshot<SeabayUser> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    lastNameController.text = snapshot.data?.lastName ?? '';
                    firstNameController.text = snapshot.data?.firstName ?? '';
                    return Column(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfilePic(picUrl: snapshot.data?.profilePictureUrl ?? '', initials: '${snapshot.data?.firstName.substring(0, 1)}${snapshot.data?.lastName.substring(0, 1)}',),
                        Padding(padding: EdgeInsets.all(16.0), child: 
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        RichText(
                          textAlign: TextAlign.left,
                            text: TextSpan(
                                text: 'First Name:',
                                style: TextStyle(
                                
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(firstNameController.text, textAlign: TextAlign.left,),
                        ],),
                        Column(crossAxisAlignment: CrossAxisAlignment.start,children: [

                        RichText(
                          textAlign: TextAlign.left,
                            text: TextSpan(
                                text: 'Last Name:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(lastNameController.text),
                        ],),
                        Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                        RichText(
                          textAlign: TextAlign.left,
                            text: TextSpan(
                                text: 'Email:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(usersEmail as String),
                        ]),
                          ],),
                        ),
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
        ))
        )
        );
  }
}
