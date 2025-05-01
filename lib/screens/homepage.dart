import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/posts.dart';
import 'package:seabay_app/api/wishlists.dart';
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
  final postDb = PostsService();
  final wlDb = WishlistService();

  late List<Post> _allPosts = [];
  late List<WishList> _usersWishlists = [];
  late List<int> _wishlistPostIds = [];
  late int _userWishlistId = 0;

  var _loading = true;

  @override
  void initState() {
    super.initState();
    _getPosts();
    _getUsersWishlistedPostIds();
    _getWlId();
  }

  Future<void> _getWlId() async {
    setState(() {
      _loading = true;
    });
    try {
      _userWishlistId = await wlDb.getUserWishlistId();
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

  Future<void> _getPosts() async {
    setState(() {
      _loading = true;
    });
    try {
      List<Post> data = await postDb.getPosts();
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
      List<int> data = await wlDb.getPostsTheUserWishlisted();
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
      _getPosts();
      _getUsersWishlistedPostIds();
    });
  }

  void toggleWishlist(int postId, int wlId) async {
    setState(() {
      _loading = true;
    });
    final isWishlisted = _wishlistPostIds.contains(postId);

    if (isWishlisted) {
      wlDb.removePostFromWishlist(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Center(child: Text('Post has been removed from wishlist.'))),
      );
    } else {
      wlDb.addPostToWishlist(postId, wlId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Center(
              child: Text('Post has been saved. View post on your profile.'))));
    }
    setState(() {
      _loading = false;
    });
    _getPosts();
    _getUsersWishlistedPostIds();
    Navigator.pop(context);
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
              await postDb.deletePostById(postId);
              Navigator.pop(context);
              await _refreshPosts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Center(child: Text('Post deleted successfully!'))),
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
              await postDb.updatePost(updatedPost);
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

  void pickWishlist(int postId) async {
    setState(() {
      _loading = true;
    });
    try {
      List<WishList> data = await wlDb.getUsersWishlists();
      _usersWishlists = data;
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
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Select Wishlist'),
              content: Container(
                width: 100,
                height: 200,
                child: ListView.builder(
                    itemCount: _usersWishlists.length,
                    itemBuilder: (context, index) {
                      final wl = _usersWishlists[index];
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
        body: RefreshIndicator(
            onRefresh: () async {
              _getPosts();
              _getUsersWishlistedPostIds();
            },
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: _allPosts.length,
                    itemBuilder: (context, index) {
                      Post post = _allPosts[index];
                      bool isWishlisted = _wishlistPostIds.contains(post.id);

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    })));
  }
}
