import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

//! =========== Auth Stuff ===========

  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    return await _client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<String?> signUpWithEmailPassword(String email, String password) async {
    AuthResponse response =
        await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      return response.user?.id;
    }
    return null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? getCurrentUserEmail() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  String? getCurrentUserId() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }

  void createNewUserProfile(String id) async {
    await _client.from('User_Profiles').insert({
      'first_name': null,
      'last_name': null,
      'profile_picture': null,
      'auth_id': id
    });
  }

  Future<void> createPost(Post post) async {
    final userId = getCurrentUserId();

    await _client.from('Posts').insert({
      'title': post.title,
      'description': post.description,
      'price': post.price,
      'is_active': post.isActive,
      'user_id': userId,
    });
}

Future<void> deletePost(int postId) async {
  await _client.from('Posts').delete().match({'id': postId});
}


//! ============= Data =============

  Future<SeabayUser?> getUserProfile() async {
    var userId = getCurrentUserId();
    final results = await _client
        .from('User_Profiles')
        .select('first_name, last_name')
        .match({'auth_id': userId ?? ''});

    return SeabayUser(
        firstName: results[0]['first_name'],
        lastName: results[0]['last_name'],
        id: userId ?? '');
  }

  //* Get Posts
  Future<List<Post>> getPosts() async {
    final results = await _client
        .from('Posts')
        .select('id, title, description, price, is_active')
        .limit(20);
    
    print('Fetched Posts: $results');

    List<Post> posts = [];

    if (results.isEmpty) return posts;

    for (var post in results) {
      Post newPost = Post(
          id: post["id"],
          title: post['title'],
          description: post['description'],
          price: post['price'],
          isActive: post['is_active'],
          userId: post['user_id']);
      posts.add(newPost);
    }

    return posts;
  }

  //* Get Post By Id
  // TODO

  //* Get Wishlists
  // TODO

  //* Get Wishlist by Id
  // TODO
}

//! ============= TYPES =============
class SeabayUser {
  String firstName;
  String lastName;
  String id;

  SeabayUser(
      {required this.firstName, required this.lastName, required this.id});
}

class WishList {
  String name;
  String description;
  String userId;

  WishList(
      {required this.name, required this.description, required this.userId});
}

class Post {
  int? id;
  String title = '';
  String description = '';
  int price = 0;
  bool isActive = false;
  String? userId;

  Post(
      {required this.id,
      required this.title,
      required this.description,
      required this.price,
      required this.isActive,
      this.userId});
}
