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

class HomePageTwo extends StatefulWidget {
  const HomePageTwo({super.key});

  @override
  State<HomePageTwo> createState() => _HomePageTwoState();
}

class _HomePageTwoState extends State<HomePageTwo> {
  final currentUser = Supabase.instance.client.auth.currentUser;

  final auth = AuthService();
  final db = DbService();
  final postsDB = PostsService();
  final wlDB = WishlistService();

  late List<Post> _allPosts;
  late List<WishList> _usersWishlists;
  late List<int> _wishlistPostIds;

  var _loading = true;

  @override
  void initState() {
    super.initState();
    _getPosts();
    _getUsersWishlistedPostIds();
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

  void pickWishlist(int postId) async {
    setState(() {
      _loading = true;
    });
    try {
      List<WishList> data = await wlDB.getUsersWishlists();
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

  void toggleWishlist(int postId, int wlId) async {
    final isWishlisted = _wishlistPostIds.contains(postId);

    if (isWishlisted) {
      wlDB.removePostFromWishlist(postId);
    } else {
      wlDB.addPostToWishlist(postId, wlId);
    }
    _getPosts();
    _getUsersWishlistedPostIds();
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Homepage 2'),
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
              _getPosts();
              _getUsersWishlistedPostIds();
            },
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2),
                    itemCount: _allPosts.length,
                    itemBuilder: (context, index) {
                      Post post = _allPosts[index];
                      bool isWishlisted = _wishlistPostIds.contains(post.id);

                      return Card(
                          borderOnForeground: false,
                          color: Colors.grey[850],
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5))),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetails(post: post),
                              ),
                            ),
                            child: GridTile(
                                footer: GridTileBar(
                                  backgroundColor: Colors.grey[600],
                                  title: Text(post.title,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  subtitle: Text(
                                    '\$${post.price}',
                                    style: TextStyle(
                                        color: Colors.greenAccent[400]),
                                  ),
                                  trailing: (post.userId != currentUser!.id)
                                      ? IconButton(
                                          icon: Icon(
                                            isWishlisted
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isWishlisted
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          onPressed: () =>
                                              pickWishlist(post.id!),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deletePost(post.id!),
                                        ),
                                ),
                                child: FadeInImage(
                                    placeholder:
                                        AssetImage('assets/loading.png'),
                                    image: NetworkImage(
                                        'https://images.immediate.co.uk/production/volatile/sites/30/2017/01/Bunch-of-bananas-67e91d5.jpg'))),
                          ));
                    })));
  }
}
