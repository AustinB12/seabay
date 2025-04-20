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
  late Future<SeabayUser> _profile;
  late Future<List<Post>> _wishlistPosts;
  late Future<List<Post>> _userPosts;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void initState() {
    _profile = auth.getCurrentUserProfile();
    _wishlistPosts = db.loadWishlistedPosts();
    _userPosts = db.getPostsByUser();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<SeabayUser>(
              future: _profile,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = snapshot.data!;
                firstNameController.text = user.firstName;
                lastNameController.text = user.lastName;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('First Name: ${user.firstName}',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Last Name: ${user.lastName}',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Email: ${usersEmail ?? 'No Email'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const Divider(color: Colors.white54, height: 30),
                  ],
                );
              },
            ),

            const Text('Saved Posts (Wishlist):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            FutureBuilder<List<Post>>(
              future: _wishlistPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text('No posts in wishlist.',
                        style: TextStyle(color: Colors.white70)),
                  );
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            FutureBuilder<List<Post>>(
              future: _userPosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Text('You haven\'t posted anything yet.',
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
                        trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.edit_note, color: Colors.blue),
        tooltip: 'Edit Post',
        onPressed: () => _editPostDialog(post),
      ),
      IconButton(
        icon: Icon(
          post.isActive ? Icons.visibility_off : Icons.visibility,
          color: post.isActive ? Colors.orange : Colors.green,
        ),
        tooltip: post.isActive ? 'Set as Inactive' : 'Reactivate Post',
        onPressed: () async {
          final updated = post.copyWith(isActive: !post.isActive);
          await db.updatePost(updated);
          await _refreshUserPosts();
          
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        tooltip: 'Delete Post',
        onPressed: () async {
          await db.deletePostById(post.id!);
          await _refreshUserPosts();
          
        },
      ),
    ],
  ),

                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
