import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final SupabaseClient _client = Supabase.instance.client;

  String? getCurrentUserId() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }

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
        .select('title, description, price, is_active')
        .limit(20);

    List<Post> posts = [];

    if (results.isEmpty) return posts;

    for (var post in results) {
      Post newPost = Post(
          title: post['title'],
          description: post['description'],
          price: post['price'],
          isActive: post['is_active']);
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
  String title = '';
  String description = '';
  int price = 0;
  bool isActive = false;

  Post(
      {required this.title,
      required this.description,
      required this.price,
      required this.isActive});
}
