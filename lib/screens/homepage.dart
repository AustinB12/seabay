import 'package:flutter/material.dart';
import 'package:seabay_app/auth/auth.dart';
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
  final auth = AuthService();
  late Future<List<Post>> _posts;

  void _logout(BuildContext context) {
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

  void _goToCreatePost(BuildContext context){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostPage()),
    );
  }

  void _deletePost(int postId) async {
    await auth.deletePost(postId);

    setState((){
      _posts = auth.getPosts();
    });
  }

  @override
  void initState() {
    _posts = auth.getPosts();
    super.initState();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Homepage!'),
            Container(
              height: 300,
              child: FutureBuilder<List<Post>>(
                  future: _posts,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      final posts = snapshot.data as List<Post>;
                      
                      //final currentUserId = auth.getCurrentUserId();
                      List<Container> newPosts = [];
                      for (Post post in posts) {
                        newPosts.add(Container(
                            height: 50,
                            child: Center(
                                child: Text(
                                    '${post.title} | ${post.description} | Price: ${post.price} | Active: ${post.isActive ? 'YES' : 'NO'}'
                                    )
                                  )
                                )
                              );
                      }
                      return ListView(
                        children: newPosts,
                      );
                    } else if (snapshot.connectionState ==
                            ConnectionState.done &&
                        snapshot.hasError) {
                      return Center(
                          child: Text(
                        '${snapshot.error} occurred',
                        style: TextStyle(fontSize: 18),
                      ));
                    } else {
                      return CircularProgressIndicator();
                    }
                  }),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _goToCreatePost(context),
              child: const Text('Create Post'),
            ),
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
      ),
    );
  }
}
