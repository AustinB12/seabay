 import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/types.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/screens/post_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'profile.dart';
import 'create_post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = Supabase.instance.client.auth.currentUser;
  List<int> wishlistPostIds = [];
  final auth = AuthService();
  final db = DbService();

  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = db.getPosts();
  }

  void _logout(BuildContext context) {
    auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToProfile(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  void _goToCreatePost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = db.getPosts();
    });
  }

  void toggleWishlist(int postId, String postOwnerId) async {
    if (postOwnerId == currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can’t wishlist your own post.')),
      );
      return;
    }

    final isWishlisted = wishlistPostIds.contains(postId);

    if (isWishlisted) {
      await db.removePostIdFromWishlistJson(postId);
      setState(() {
        wishlistPostIds.remove(postId);
      });
    } else {
      await db.addPostIdtoWishListJson(postId);
      setState(() {
        wishlistPostIds.add(postId);
      });
    }
  }

  void _deletePost(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await db.deletePostById(postId);
              Navigator.pop(context);
              await _refreshPosts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post deleted successfully!')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void editPostDialog(Post post) {
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
              Navigator.pop(context);
              await _refreshPosts();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _goToCreatePost(context),
            tooltip: 'Create Post',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _goToProfile(context),
            tooltip: 'Profile Page',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isWishlisted = wishlistPostIds.contains(post.id);

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: ListTile(
                  leading: Tooltip(
                    message: post.isActive ? 'Active' : 'Inactive',
                    child: Icon(
                      post.isActive ? Icons.check_circle : Icons.crisis_alert_sharp,
                      color: post.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(post.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${post.description ?? ''}\n\$${post.price}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (post.userId != currentUser!.id)
                        IconButton(
                          icon: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => toggleWishlist(post.id!, post.userId),
                        ),
                      if (post.userId == currentUser!.id)
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.blue),
                          onPressed: () => editPostDialog(post),
                        ),
                      if (post.userId == currentUser!.id)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePost(post.id!),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetails(post: post),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}