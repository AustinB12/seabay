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
  List<int> wishlistedPostIds = [];

  @override
  void initState() {
    super.initState();
    _postsFuture = db.getPosts();
    loadWishList();
  }

  void loadWishList() async {
    final wishlistPosts = await db.loadWishlistedPosts();
    setState(() {
      wishlistPostIds = wishlistPosts.map((e) => e.id!).toList();
    });
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
        const SnackBar(content: Center(child: Text('You can’t wishlist your own post.'))),
      );
      return;
    }

    final isWishlisted = wishlistPostIds.contains(postId);

    if (isWishlisted) {
      await db.removePostIdFromWishlistJson(postId);
      setState(() {
        wishlistPostIds.remove(postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text('Post has been removed from wishlist.'))),
      );
    } else {
      await db.addPostIdtoWishListJson(postId);
      setState(() {
        wishlistPostIds.add(postId);
      });
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar(content: Center(child: Text('Post has been saved. View post on your profile.')))
      );
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
                const SnackBar(content: Center(child: Text('Post deleted successfully!'))),
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

String _commasAddedToPrice(int? price) {
  if (price == null) return '';
  return price.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match numbers) => '${numbers[1]},',
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

          final posts = snapshot.data!.where((post) => post.isActive).toList();

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isWishlisted = wishlistPostIds.contains(post.id);

          return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetails(post: post),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 11.0),
                          child: SizedBox(
                            height: 80,
                          child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[800],
                            ),
                            child: post.imageUrls != null && post.imageUrls!.isNotEmpty
                                ?  ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    post.imageUrls!.first,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(Icons.image, color: Colors.white30),
                                ),
                              )
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                child:
                                Text(post.title,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white))),
                                const SizedBox(height: 4),
                                Text(post.description ?? '',
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Center(
                                child: Text('\$${_commasAddedToPrice(post.price)}',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent))),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Tooltip(
                                message: post.isActive ? 'Active' : 'Inactive',
                                child: Icon(
                                  post.isActive
                                      ? Icons.check_circle
                                      : Icons.crisis_alert_sharp,
                                  color: post.isActive ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (post.userId != currentUser!.id)
                                IconButton(
                                  icon: Icon(
                                    isWishlisted
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isWishlisted ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () =>
                                      toggleWishlist(post.id!, post.userId),
                                  iconSize: 20,
                                ),
                              if (post.userId == currentUser!.id)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => editPostDialog(post),
                                  iconSize: 20,
                                ),
                              if (post.userId == currentUser!.id)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePost(post.id!),
                                  iconSize: 20,
                                ),
                            ],
                          ),
                        ],
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
