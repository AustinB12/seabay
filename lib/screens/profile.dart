import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/posts.dart';
import 'package:seabay_app/api/types.dart';
import 'package:seabay_app/api/wishlists.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/components/profile_picture.dart';
import 'package:seabay_app/screens/post_details.dart';
import 'login.dart';
import 'homepage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final db = DbService();
  final postsDB = PostsService();
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

  void _goToPostDetails(BuildContext context, Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PostDetails(
                post: post,
              )),
    );
  }

  Future<void> _refreshUserPosts() async {
    setState(() {
      _userPosts = db.getPostsByUser();
    });
  }

  void _deletePost(int postId) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Delete Post'),
                content: const Text('Are you sure you to delete this post?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                      onPressed: () async {
                        postsDB.deletePostById(postId);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Post deleted successfully!')),
                        );
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)))
                ]));
  }

  void _editPostDialog(Post post) {
    final titleController = TextEditingController(text: post.title);
    final descController = TextEditingController(text: post.description);
    final priceController = TextEditingController(text: post.price?.toString());
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
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
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    if (errorMessage != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          )),
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

                        await postsDB.updatePost(updatedPost);
                        await _refreshUserPosts();
                        Navigator.pop(context);
                        setState(() {
                          _wishlistPosts = db.loadWishlistedPosts();
                          _userPosts = db.getPostsByUser();
                        });
                      },
                      child: const Text('Save'),
                    ),
                    if (errorMessage != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ))
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final description = descController.text.trim();
                      final price = priceController.text.trim();

                      if (title.isEmpty ||
                          description.isEmpty ||
                          price.isEmpty) {
                        setState(() {
                          errorMessage = 'All fields are required.';
                        });
                        return;
                      }

                      final priceValue = int.tryParse(price);
                      if (priceValue == null || priceValue <= 0) {
                        setState(() {
                          errorMessage = 'Price cannot include letters.';
                        });
                        return;
                      }

                      final updatedPost = Post(
                        id: post.id,
                        title: titleController.text,
                        description: descController.text,
                        price: int.tryParse(priceController.text) ?? 0,
                        isActive: post.isActive,
                        userId: post.userId,
                        imageUrls: post.imageUrls,
                      );

                      await postsDB.updatePost(updatedPost);
                      await _refreshUserPosts();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Post updated successfully.')),
                      );
                      setState(() {
                        _wishlistPosts = db.loadWishlistedPosts();
                        _userPosts = db.getPostsByUser();
                      });
                    },
                    child: const Text('Save'),
                  ),
                ],
              )),
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
              Text(post.description!,
                  style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 10),
            Text('Price: \$${post.price}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
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

  void _editProfileDialog() {
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
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
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorMessage ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
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
                    final firstName = firstNameController.text.trim();
                    final lastName = lastNameController.text.trim();
                    final regName = RegExp(r'^[a-zA-Z]+$');

                    if (firstName.isEmpty || lastName.isEmpty) {
                      setStateDialog(() {
                        errorMessage = 'First and Last Name cannot be empty.';
                      });
                      return;
                    }

                    if (!regName.hasMatch(firstName) ||
                        !regName.hasMatch(lastName)) {
                      setStateDialog(() {
                        errorMessage = 'Names can only include letters';
                      });
                      return;
                    }

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
            );
          },
        );
      },
    );
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
        child: Column(
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
              builder: (context, AsyncSnapshot<SeabayUser> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final user = snapshot.data!;
                  lastNameController.text = snapshot.data?.lastName ?? '';
                  firstNameController.text = snapshot.data?.firstName ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfilePic(
                        picUrl: user.profilePictureUrl ?? '',
                        initials:
                            '${user.firstName.substring(0, 1)}${user.lastName.substring(0, 1)}',
                      ),
                      const SizedBox(height: 20),
                      Text('First Name: ${user.firstName}',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Last Name: ${user.lastName}',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Email: ${usersEmail ?? 'No Email'}',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                      const Divider(color: Colors.white54, height: 30),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            const Text('Wishlists:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            FutureBuilder<List<Post>>(
              future: _wishlistPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Text('No posts in wishlist.',
                      style: TextStyle(color: Colors.white70));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Tooltip(
                          message: post.isActive ? 'Active' : 'Inactive',
                          child: Icon(
                            post.isActive
                                ? Icons.check_circle
                                : Icons.crisis_alert_sharp,
                            color: post.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(post.title,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${post.description ?? ''}\n\$${post.price}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFromWishlist(post.id!),
                          tooltip: 'Remove from Wishlist',
                        ),
                        onTap: () => _showPostDetails(post),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(color: Colors.white54, height: 40),
            const Text('My Posts:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: postsDB.usersPosts,
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error'));
                }

                final posts = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = Post.fromMap(posts[index]);
                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        onTap: () => _goToPostDetails(context, post),
                        leading: Tooltip(
                          message: post.isActive ? 'Active' : 'Inactive',
                          child: Icon(
                            post.isActive
                                ? Icons.check_circle
                                : Icons.crisis_alert_sharp,
                            color: post.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(post.title,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          '${post.description ?? ''}\n\$${post.price}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note,
                                  color: Colors.blue),
                              tooltip: 'Edit Post',
                              onPressed: () => _editPostDialog(post),
                            ),
                            IconButton(
                              icon: Icon(
                                post.isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: post.isActive
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              tooltip: post.isActive
                                  ? 'Set as Inactive'
                                  : 'Reactivate Post',
                              onPressed: () async {
                                final updated =
                                    post.copyWith(isActive: !post.isActive);
                                await postsDB.updatePost(updated);
                                await _refreshUserPosts();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.red),
                              tooltip: 'Delete Post',
                              onPressed: () => _deletePost(post.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
