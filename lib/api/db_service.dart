import 'package:seabay_app/api/types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  final SupabaseClient _client = Supabase.instance.client;

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
      Supabase.instance.client.from('Posts').select('*').order('created_at', ascending: false).asStream();

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
  Future<Post?> getPostById(int postId) async {
    final results = await _client
        .from('Posts')
        .select('id, title, description, price, is_active, user_id, images')
        .eq('id', postId);

    if (results.isEmpty) return null;

    return Post.fromMap(results.first);
  }

  Future<List<Post>> getPostsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final result = await _client
        .from('Posts')
        .select('id, title, description, price, is_active, user_id')
        .inFilter('id', ids);

    return result.map<Post>((row) => Post.fromMap(row)).toList();
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

//* Mark Post Inactive
  Future<void> markPostInactive(int postId) async {
  await _client
      .from('Posts')
      .update({'is_active': false})
      .eq('id', postId);
}

//* Hard Delete Post and Clean Wishlists
//* This function deletes a post and removes its ID from all wishlists
//* that contain it. It first deletes the post from the 'Posts' table,
//* then retrieves all wishlists, checks if the post ID is present in
//* each wishlist, and if so, updates the wishlist by removing the post ID.
Future<void> hardDeletePostAndCleanWishlists(int postId) async {
  await _client.from('Posts').delete().eq('id', postId);

  final wishlists = await _client
      .from('Wish_Lists')
      .select('id, Post_Ids');

  for (var wl in wishlists) {
    final List<dynamic> postIds = wl['Post_Ids'] ?? [];
    final int wishlistId = wl['id'];

    if (postIds.contains(postId)) {
      final updatedPostIds = List<dynamic>.from(postIds)..remove(postId);

      await _client
          .from('Wish_Lists')
          .update({'Post_Ids': updatedPostIds})
          .eq('id', wishlistId);
    }
  }
}

//* Remove Post ID From All Wishlists (Batching or reusable)
Future<void> removePostIdFromAllWishlists(int postId) async {
  final wishlists = await _client
      .from('Wish_Lists')
      .select('id, Post_Ids');

  for (var wl in wishlists) {
    final List<dynamic> postIds = wl['Post_Ids'] ?? [];
    final int wishlistId = wl['id'];

    if (postIds.contains(postId)) {
      final updatedPostIds = List<dynamic>.from(postIds)..remove(postId);

      await _client
          .from('Wish_Lists')
          .update({'Post_Ids': updatedPostIds})
          .eq('id', wishlistId);
    }
  }
}

  Future<List<Post>> loadWishlistedPosts() async {
  final result = await _client
      .from('Wish_Lists')
      .select('Post_Ids')
      .eq('user_id', DbService.currentUserId ?? '')
      .limit(1)
      .single();

  final rawPostIds = result['Post_Ids'];
  final List<int> postIds = rawPostIds == null
      ? []
      : List<int>.from(rawPostIds.map((id) => id as int));

  return getPostsByIds(postIds);
}

Future<List<Post>> getPostsByUser() async {
  final userId = currentUserId;
  if (userId == null) return [];

  final results = await _client
      .from('Posts')
      .select('id, title, description, price, is_active, user_id')
      .eq('user_id', userId);

  return results.map<Post>((row) => Post.fromMap(row)).toList();
}



//todo fix this
  //* Update Post
  Future<bool> updatePost(Post post) async {
    final results = await _client.from('Posts').update({
      'title': post.title,
      'description': post.description,
      'is_active': post.isActive,
      'price': post.price,
      'images': post.imageUrls ?? [],
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

  //* Create New User Default Wishlist
  Future createDefaultWishlist(String? userID) async {
    await _client.from('Wish_Lists').insert({
      'name': 'My Wishlist',
      'description': 'My default wishlist',
      'user_id': userID
    });
  }

  Future<void> removePostIdFromWishlistJson(int postId) async {
  final userId = currentUserId ?? '';

  final result = await _client
      .from('Wish_Lists')
      .select('id, Post_Ids')
      .eq('user_id', userId)
      .limit(1)
      .single();

  final wishlistId = result['id'];
  final rawPostIds = result['Post_Ids'];

  final List<dynamic> currentPostIds =
      (rawPostIds is List) ? List.from(rawPostIds) : [];

  currentPostIds.remove(postId);

  await _client.from('Wish_Lists').update({
    'Post_Ids': currentPostIds,
  }).eq('id', wishlistId);
}


  Future<void> addPostIdtoWishListJson(int postId) async {
    final results = await _client
        .from('Wish_Lists')
        .select('id, Post_Ids')
        .eq('user_id', currentUserId ?? '')
        .limit(1)
        .single();

    final wishlistId = results['id'];
    final rawPostIds = results['Post_Ids'];

    final List<dynamic> currentPostIds =
      (rawPostIds is List) ? List.from(rawPostIds) : [];

  if (!currentPostIds.contains(postId)) {
    currentPostIds.add(postId);

    await _client.from('Wish_Lists').update({
      'Post_Ids': currentPostIds,
    }).eq('id', wishlistId);
  }
        
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

