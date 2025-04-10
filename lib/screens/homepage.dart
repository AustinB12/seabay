import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'dashboard.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = Supabase.instance.client.auth.currentUser;
  List<Map<String, dynamic>> posts = [];
  List<int> wishlistPostIds = []; // 👈 Simple list of IDs
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPostsAndWishlist();
  }

  void loadPostsAndWishlist() async {
    try {
      final postData = await Supabase.instance.client
          .from("Posts")
          .select();

      final wishlistData = await Supabase.instance.client
          .from("Wish_Lists")
          .select()
          .eq('user_id', currentUser!.id);

      setState(() {
        posts = List<Map<String, dynamic>>.from(postData);
        wishlistPostIds = wishlistData.map<int>((item) => item['post_id'] as int).toList();
        isLoading = false;
      });
    } catch (error) {
      print('Error: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

void toggleWishlist(int postId) async {
  // Find the post
  final post = posts.firstWhere((p) => p['id'] == postId);

  // Don't allow adding your own post
  if (post['user_id'] == currentUser!.id) {
    print("Can't wishlist your own post.");
    return;
  }

  bool alreadyInWishlist = wishlistPostIds.contains(postId);

  // Update UI first
  setState(() {
    if (alreadyInWishlist) {
      wishlistPostIds.remove(postId);
    } else {
      wishlistPostIds.add(postId);
    }
  });

  try {
    if (alreadyInWishlist) {
      await Supabase.instance.client
          .from('Wish_Lists')
          .delete()
          .eq('id', postId)
          .eq('user_id', currentUser!.id);
    } else {
      await Supabase.instance.client.from('Wish_Lists').insert({
        'id': postId,
        'user_id': currentUser!.id,
      });
    }
  } catch (e) {
    print('Error updating wishlist: $e');
  }
}


  void _logout(BuildContext context) {

    //TODO actually log out the user

    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homepage'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                const Text('Welcome to the Homepage!'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final postId = post['id'];
                      final isWishlisted = wishlistPostIds.contains(postId);

                      return ListTile(
                        title: Text(post['title'] ?? 'No Title'),
                        subtitle: Text(
                            '${post['description']} | Price: ${post['price']} | Active: ${post['is_active'] ? 'YES' : 'NO'}'),
                        trailing: post['user_id'] != currentUser!.id
                        ? IconButton(
                            icon: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isWishlisted ? Colors.red : Colors.grey,
                            ),
                            onPressed: () => toggleWishlist(postId),
                          )
                        : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _goToDashboard(context),
                  child: const Text('Back to Dashboard'),
                ),
                ElevatedButton(
                  onPressed: () => _goToProfile(context),
                  child: const Text('Go to profile'),
                ),
              ],
            ),
    );
  }
}
