import 'package:supabase_flutter/supabase_flutter.dart';

final _client = Supabase.instance.client;

class WishlistService {
  static String get currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  final postsToWishlistsStream =
      _client.from('Posts_To_Wishlists').stream(primaryKey: ['id']);

  Future addPostToWishlist(int postId, int listId) async {
    await _client
        .from('Posts_To_Wishlists')
        .insert({'wishlist_id': listId, 'post_id': postId});
  }

  Future removePostFromWishlist(int postId, int listId) async {
    await _client
        .from('Posts_To_Wishlists')
        .delete()
        .eq('wishlist_id', listId)
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
