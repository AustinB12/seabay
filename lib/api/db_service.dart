import 'package:seabay_app/api/types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final SupabaseClient _client = Supabase.instance.client;

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

  final usersPosts = currentUserId!.isNotEmpty ? Supabase.instance.client
      .from('Posts')
      .select('*')
      .eq('user_id', currentUserId ?? '')
      .asStream()
      : null;

  final usersWishlists = currentUserId!.isNotEmpty ? Supabase.instance.client
      .from('Wish_Lists')
      .select('*')
      .eq('user_id', currentUserId ?? '')
      .asStream() : null;

  final allPosts =
      Supabase.instance.client.from('Posts').select('*').asStream();

  final postIdsInWishlists =currentUserId!.isNotEmpty ?  Supabase.instance.client
      .from('Posts_To_Wishlists')
      .select('post_id, Wish_Lists(id, user_id)')
      .eq('user_id', currentUserId ?? '')
      .asStream() : null;

  Future getPostIdsInWishlists() {
    return _client
        .from('Posts_To_Wishlists')
        .select('post_id, Wish_Lists(id, user_id)')
        .eq('user_id', currentUserId ?? '');
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
        .select('id, title, description, price, is_active, user_id, images')
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

//todo fix this
  //* Update Post
  Future<bool> updatePost(Post post) async {
    final results = await _client.from('Posts').update({
      'title': post.title,
      'description': post.description,
      'is_active': post.isActive,
      'price': post.price,
      'images': post.imageUrls,
    }).eq('id', post.id ?? 0);

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
        .eq('user_id', currentUserId ?? '')
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
      'user_id': currentUserId ?? ''
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

