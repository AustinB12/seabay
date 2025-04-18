import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final SupabaseClient _client = Supabase.instance.client;

  String? getCurrentUserId() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }

  Future<SeabayUser?> getUserProfile(String authId) async {
    final results = await _client
        .from('User_Profiles')
        .select('id, first_name, last_name, auth_id')
        .eq('auth_id', authId);

    return SeabayUser.fromMap(results.first);
  }

  String? userId;

  DbService() : userId = null;

  static String? get currentUserId =>
      Supabase.instance.client.auth.currentSession?.user.id;

  final usersPosts = Supabase.instance.client
      .from('Posts')
      .select('*')
      .eq('user_id', currentUserId as String)
      .asStream();

  final usersWishlists = Supabase.instance.client
      .from('Wish_Lists')
      .select('*')
      .eq('user_id', currentUserId as String)
      .asStream();

  final allPosts =
      Supabase.instance.client.from('Posts').select('*').asStream();

  final profileStream = Supabase.instance.client
      .from('Posts')
      .select('*')
      .eq('user_id', currentUserId as String)
      .asStream();

  Future<SeabayUser> getCurrentUserProfile() async {
    final results = await _client
        .from('User_Profiles')
        .select('id, first_name, last_name, auth_id')
        .eq('auth_id', currentUserId as String);

    return SeabayUser.fromMap(results.first);
  }

  Future createNewUserProfile(String authId) async {
    await _client.from('User_Profiles').insert({'auth_id': authId});
  }

  Future updateUserProfile(SeabayUser user) async {
    await _client
        .from('User_Profiles')
        .update({'first_name': user.firstName, 'last_name': user.lastName}).eq(
            'auth_id', currentUserId as String);
  }

  //* Get Posts
  Future<List<Post>> getPosts() async {
    final results = await _client
        .from('Posts')
        .select('id, title, description, price, is_active, user_id')
        .limit(50);

    if (results.isEmpty) return [];

    return results.map((postMap) => Post.fromMap(postMap)).toList();
  }

  //* Get Post By Id
  Future<Post?> getPostById(String postId) async {
    final results = await _client
        .from('Posts')
        .select('id, title, description, price, is_active, user_id')
        .eq('id', postId);

    if (results.isEmpty) return null;

    return Post.fromMap(results.first);
  }

  //* Create Post
  Future createPost(Post newPost) async {
    await _client.from('Posts').insert({
      'title': newPost.title,
      'description': newPost.description,
      'price': newPost.price,
      'user_id': newPost.userId
    });
  }

  //* Update Post
  Future<bool> updatePost(SeabayUser user) async {
    final results = await _client.from('Posts').update({
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'auth_id': user.authId,
    }).eq('id', user.id as int);

    return results.isEmpty;
  }

  //* Delete Post
  Future<bool> deletePostById(int postId) async {
    final result =
        await _client.from('Posts').delete().eq('id', postId).select();

    return result.isEmpty;
  }

  //* Get Wishlists
  Future<List<WishList>> getWishlists() async {
    final results = await _client
        .from('Wish_Lists')
        .select('id, name, description, user_id')
        .eq('user_id', currentUserId as String)
        .limit(50);

    if (results.isEmpty) return [];

    return results.map((wishlistMap) => WishList.fromMap(wishlistMap)).toList();
  }

  //* Get Wishlist by Id
  Future<WishList?> getWishlistById(String wishlistId) async {
    final results = await _client
        .from('Wish_Lists')
        .select('id, name, description, user_id')
        .eq('id', wishlistId);

    if (results.isEmpty) return null;

    return WishList.fromMap(results.first);
  }

  //* Create Wishlist
  Future createWishlist(String name, String description) async {
    await _client.from('Wish_Lists').insert({
      'name': name,
      'description': description,
      'user_id': currentUserId as String
    });
  }

  //* Update Wishlist
  Future<bool> updateWishlist(WishList wishlist) async {
    final results = await _client.from('Wish_Lists').update({
      'id': wishlist.id,
      'name': wishlist.name,
      'description': wishlist.description,
      'user_id': wishlist.userId,
    }).eq('id', wishlist.id);

    return results.isEmpty;
  }

  //* Delete Wishlist
  Future<bool> deleteWishlistById(int wishlistId) async {
    final result =
        await _client.from('Wish_Lists').delete().eq('id', wishlistId).select();

    return result.isEmpty;
  }

  //* Add Post To Wishlist
  Future<bool> addPostToWishlist(int postId, int wishlistId) async {
    final result = await _client
        .from('Posts_To_Wishlists')
        .insert({'wishlist_id': wishlistId, 'post_id': postId}).select();

    return result.isNotEmpty;
  }
}

//! ============= TYPES =============
class SeabayUser {
  int? id;
  String? authId;
  String firstName;
  String lastName;

  SeabayUser(
      {this.id, required this.firstName, required this.lastName, this.authId});

  factory SeabayUser.fromMap(Map<String, dynamic> map) {
    return SeabayUser(
      id: map['id'] as int,
      authId: map['auth_id'] as String,
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authId': authId,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}

class WishList {
  int id;
  String name;
  String description;
  String userId;

  WishList(
      {required this.id,
      required this.name,
      required this.description,
      required this.userId});

  factory WishList.fromMap(Map<String, dynamic> map) {
    return WishList(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      userId: map['user_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'userId': userId,
    };
  }
}

class Post {
  int? id;
  String title = '';
  String? description = '';
  int? price = 0;
  bool isActive = false;
  String userId;

  Post(
      {required this.title,
      this.id,
      this.description,
      this.price,
      required this.isActive,
      required this.userId});

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      price: map['price'] as int,
      isActive: map['is_active'] as bool,
      userId: map['user_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'isActive': isActive,
      'userId': userId,
    };
  }
}
