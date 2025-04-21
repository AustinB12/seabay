import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/types.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/screens/post_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'dashboard.dart';
import 'profile.dart';
import 'create_post.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = Supabase.instance.client.auth.currentUser;
  List<Post> posts = [];
  List<int> wishlistPostIds = []; 
  List<WishList> usersWishlists = [];
  bool isLoading = true;

  final auth = AuthService();
  final db = DbService();

  @override
  void initState() {
    super.initState();
    loadPostsAndWishlist();
  }

void loadPostsAndWishlist() async {
  try {
    final postsData = await db.getPosts();

    final wishlistResults = await Supabase.instance.client
        .from('Wish_Lists')
        .select('Post_Ids')
        .eq('user_id', currentUser!.id)
        .limit(1)
        .maybeSingle();

    final List<dynamic> rawPostIds = wishlistResults?['Post_Ids'] ?? [];
    final List<int> ids = rawPostIds.cast<int>();

    setState(() {
      posts = postsData;
      wishlistPostIds = ids;
      isLoading = false;
    });
  } catch (error) {
    log('Error: $error');
    setState(() {
      isLoading = false;
    });
  }
}



  
void toggleWishlist(int postId, String postOwnerId) async {
  if (postOwnerId == currentUser!.id) {
    // Prevent adding own posts
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You can’t wishlist your own post.')),
    );
    return;
  }

  final isWishlisted = wishlistPostIds.contains(postId);

  if (isWishlisted) {
    await db.removePostIdFromWishlistJson(postId);
  } else {
    await db.addPostIdtoWishListJson(postId);
  }

  loadPostsAndWishlist();
}



  void _logout(BuildContext context) {
    auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
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
                        Navigator.pop(context);
                        await db.deletePostById(postId);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Homepage'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => _goToDashboard(context),
              tooltip: 'Dashboard',
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
        floatingActionButton: FloatingActionButton(
            onPressed: () => _goToCreatePost(context),
            child: const Icon(Icons.add)),
        body: StreamBuilder(
            stream: db.allPosts,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data;

              return ListView.builder(
                  itemCount: posts?.length,
                  itemBuilder: (context, index) {
                    final post = Post.fromMap(posts![index]);
                    final isWishlisted = wishlistPostIds.contains(post.id);

                    return ListTile(
                      title: Text(post.title),
                      subtitle: Text(
                          '${post.description} | Price: ${post.price} | Active: ${post.isActive ? 'YES' : 'NO'}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (post.userId != currentUser!.id)
                          IconButton(
                            icon: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isWishlisted ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => toggleWishlist(post.id!, post.userId),
                          ),
                        if (post.userId == currentUser!.id)
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.yellow),
                            onPressed: () => _deletePost(post.id!),
                          ),
                      ]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetails(post: post),
                        ),
                      ),
                    );
                  });
            }));
  }
}
