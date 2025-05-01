import 'package:supabase_flutter/supabase_flutter.dart';

final _client = Supabase.instance.client;

class WishlistService {
  static String get currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  Future addPostToWishlist(int postId, int listId) async {
    await _client
        .from('Posts_To_Wishlists')
        .insert({'wishlist_id': listId, 'post_id': postId});
  }

  Future removePostFromWishlist(int postId) async {
    await _client
        .from('Posts_To_Wishlists')
        .delete()
        .inFilter('wishlist_id',
            (await getUsersWishlists()).map((x) => x.id).toList())
        .eq('post_id', postId);
  }

  Future<List<WishList>> getUsersWishlists() async {
    final result = await _client
        .from('Wish_Lists')
        .select('*')
        .eq('user_id', currentUserId);
    if (result.isEmpty) return [];

    return result.map((data) => WishList.fromMap(data)).toList();
  }

  Future<int> getUserWishlistId() async {
    var result = await _client
        .from('Wish_Lists')
        .select('id')
        .eq('user_id', currentUserId);
    return result.first['id'];
  }

  Future getPostsTheUserWishlisted() async {
    //* Grab all the users Wishlists
    final wlIds = await _client
        .from('Wish_Lists')
        .select('id')
        .eq('user_id', _client.auth.currentUser!.id);

    //* Map it to a list of IDs
    final ids = wlIds.map((w) => w['id'] as int).toList();
    //* Use that list to find the posts
    final postIdsInUsersWishlists = await _client
        .from('Posts_To_Wishlists')
        .select('post_id')
        .inFilter('wishlist_id', ids);

    //* Map that to a list of post IDs
    final postIds =
        postIdsInUsersWishlists.map((z) => z['post_id'] as int).toList();

    //* The IDs of posts the user has wishlisted
    return postIds;
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

class PostsToWishlists {}
