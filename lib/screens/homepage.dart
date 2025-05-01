import 'package:seabay_app/api/wishlists.dart';
import 'login.dart';
import 'profile.dart';
import 'create_post.dart';
import 'package:flutter/material.dart';
import 'package:seabay_app/api/posts.dart';
import 'package:seabay_app/auth/auth.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/screens/post_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final postsDB = PostsService();
  final wlDB = WishlistService();

  List<int>? postIdsTheUserWishlisted;
  List<WishList> usersWishlists = [];

  late List<Post> _allPosts;
  late List<WishList> _usersWishlists;
  late List<int> _wishlistPostIds;

  late Future<List<Post>> _postsFuture;
  var _loading = true;

  @override
  void initState() {
    loadWlPosts();
    _getPosts();
    _getUsersWishlistedPostIds();
    super.initState();
  }

  Future<void> _getPosts() async {
    setState(() {
      _loading = true;
    });
    try {
      List<Post> data = await postsDB.getPosts();
      _allPosts = data;
    } catch (error) {
      if (mounted) {
        // context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _getUsersWishlistedPostIds() async {
    setState(() {
      _loading = true;
    });
    try {
      List<int> data = await wlDB.getPostsTheUserWishlisted();
      _wishlistPostIds = data;
    } catch (error) {
      if (mounted) {
        // context.showSnackBar('Unexpected error occurred', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void toggleWishlist(int postId, int wlId) async {
    final isWishlisted = _wishlistPostIds.contains(postId);

    if (isWishlisted) {
      wlDB.removePostFromWishlist(postId);
    } else {
      wlDB.addPostToWishlist(postId, wlId);
    }
    // _getPosts();
    // _getUsersWishlistedPostIds();
    Navigator.pop(context);
  }

  Future<void> loadWlPosts() async {
    postIdsTheUserWishlisted = await wlDB.getPostsTheUserWishlisted();
    usersWishlists = await wlDB.getUsersWishlists();
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

  void pickWishlist(int postId) async {
    if (postIdsTheUserWishlisted!.contains(postId)) {
      await wlDB.removePostFromWishlist(postId);
      await loadWlPosts();
      return;
    }
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Select Wishlist'),
              content: Container(
                width: 100,
                height: 200,
                child: ListView.builder(
                    itemCount: usersWishlists.length,
                    itemBuilder: (context, index) {
                      final wl = usersWishlists[index];
                      return Card(
                        child: ListTile(
                          onTap: () => toggleWishlist(postId, wl.id),
                          title: Text(wl.name),
                          subtitle:
                              Text('${wl.description.substring(0, 12)}...'),
                        ),
                      );
                    }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ));
    Future<void> _refreshPosts() async {
      setState(() {
        _postsFuture = db.getPosts();
      });
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
                await postsDB.deletePostById(postId);
                Navigator.pop(context);
                await _refreshPosts();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Center(child: Text('Post deleted successfully!'))),
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
      final priceController =
          TextEditingController(text: post.price?.toString());

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
                await postsDB.updatePost(updatedPost);
                //   final updatedPosts = await db.getPosts();

                //   setState(() {
                //     posts = updatedPosts;
                //   });

                Navigator.pop(context);
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
                tooltip: 'Go to profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context),
                tooltip: 'Sign Out',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              return loadWlPosts();
            },
            child: StreamBuilder(
              stream: postsDB.postsStream,
              builder: (context, snapshot) {
                print(postIdsTheUserWishlisted);
                if (!snapshot.hasData && !snapshot.hasError ||
                    snapshot.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error'));
                }

                Iterable<Post>? postss =
                    snapshot.data?.map((datum) => Post.fromMap(datum));
                List<Post> posts =
                    postss!.where((post) => post.isActive).toList();

                if (posts.isEmpty) {
                  return Center(child: Text("No Posts"));
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isWishlisted = wishlistPostIds.contains(post.id);
                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                              // Image preview (placeholder if no image)
                              Padding(
                                padding: const EdgeInsets.only(top: 11.0),
                                child: SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.grey[800],
                                        ),
                                        child: post.imageUrls != null &&
                                                post.imageUrls!.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  post.imageUrls!.first,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : const Icon(Icons.image,
                                                color: Colors.white30),
                                      ),
                                    )),
                              ),

                              const SizedBox(width: 12),

                              // Title, desc, price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                        child: Text(post.title,
                                            style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white))),
                                    const SizedBox(height: 4),
                                    Text(post.description ?? '',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Center(
                                        child: Text(
                                            '\$${_commasAddedToPrice(post.price)}',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.greenAccent))),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Actions (wishlist, edit, delete)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Tooltip(
                                    message:
                                        post.isActive ? 'Active' : 'Inactive',
                                    child: Icon(
                                      post.isActive
                                          ? Icons.check_circle
                                          : Icons.crisis_alert_sharp,
                                      color: post.isActive
                                          ? Colors.green
                                          : Colors.red,
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
                                        color: isWishlisted
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      onPressed: () => pickWishlist(post.id!),
                                      iconSize: 20,
                                    ),
                                  if (post.userId == currentUser!.id)
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => editPostDialog(post),
                                      iconSize: 20,
                                    ),
                                  if (post.userId == currentUser!.id)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
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
          ));
    }
  }
}
