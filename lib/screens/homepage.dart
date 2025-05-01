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

  void toggleWishlist(int postId, String postOwnerId) async {
    if (postOwnerId == currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can’t wishlist your own post.')),
      );
      return;
    }

    final isWishlisted = wishlistPostIds.contains(postId);

    if (isWishlisted) {
      // wlDB.removePostFromWishlist(postId, listId)
      await db.removePostIdFromWishlistJson(postId);
    } else {
      // wlDB.addPostToWishlist(postId, listId)
      await db.addPostIdtoWishListJson(postId);
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

  void pickWishlist(int postId) async {
    List<WishList> wls = await wlDB.getUsersWishlists();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Select Wishlist'),
              content: Container(
                height: 200,
                child: ListView.builder(
                    itemCount: wls.length,
                    itemBuilder: (context, index) {
                      final wl = wls[index];
                      return Card(
                        child: ListTile(
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

  @override
  Widget build(BuildContext context) {
    wlDB.postsToWishlistsStream.listen((List<Map<String, dynamic>> data) {
      print(data);
    });

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
        body: StreamBuilder(
            stream: postsDB.postsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error'));
              }

              final posts = snapshot.data;

              return GridView.builder(
                itemCount: posts?.length,
                itemBuilder: (context, index) {
                  final post = Post.fromMap(posts![index]);
                  final isWishlisted = wishlistPostIds.contains(post.id);
                  return Card(
                      borderOnForeground: false,
                      color: Colors.grey[850],
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(5))),
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
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '\$${post.price}',
                                style:
                                    TextStyle(color: Colors.greenAccent[400]),
                              ),
                              //   leading: Tooltip(
                              //     message: post.isActive ? 'Active' : 'Inactive',
                              //     child: Icon(
                              //       post.isActive
                              //           ? Icons.check_circle
                              //           : Icons.crisis_alert_sharp,
                              //       color:
                              //           post.isActive ? Colors.green : Colors.red,
                              //     ),
                              //   ),
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
                                      onPressed: () => pickWishlist(post.id!),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _deletePost(post.id!),
                                    ),

                              //   Row(
                              //     mainAxisSize: MainAxisSize.min,
                              //     children: [
                              // if (post.userId != currentUser!.id)
                              //   IconButton(
                              //     icon: Icon(
                              //       isWishlisted
                              //           ? Icons.favorite
                              //           : Icons.favorite_border,
                              //       color: isWishlisted
                              //           ? Colors.red
                              //           : Colors.grey,
                              //     ),
                              //     onPressed: () =>
                              //         toggleWishlist(post.id!, post.userId),
                              //   ),
                              //   if (post.userId == currentUser!.id)
                              //     IconButton(
                              //       icon: const Icon(Icons.edit_note,
                              //           color: Colors.blue),
                              //       onPressed: () => editPostDialog(post),
                              //     ),
                              //   if (post.userId == currentUser!.id)
                              //     IconButton(
                              //       icon: const Icon(Icons.delete,
                              //           color: Colors.red),
                              //       onPressed: () => _deletePost(post.id!),
                              //     ),
                              // ],
                              //   ),
                            ),
                            child: FadeInImage(
                                placeholder: AssetImage('assets/loading.png'),
                                image: NetworkImage(
                                    'https://images.immediate.co.uk/production/volatile/sites/30/2017/01/Bunch-of-bananas-67e91d5.jpg'))),
                      ));
                },
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 2, mainAxisSpacing: 2),
              );
            }));
  }
}
