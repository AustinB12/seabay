import 'package:supabase_flutter/supabase_flutter.dart';

final _client = Supabase.instance.client;

class PostsService {
  static String get currentUserId =>
      Supabase.instance.client.auth.currentUser!.id;

  final postsStream = _client
      .from('Posts')
      .stream(primaryKey: ['id'])
      .neq('user_id', currentUserId)
      .order('created_at');

  final usersPosts = _client
      .from('Posts')
      .stream(primaryKey: ['id']).eq('user_id', currentUserId);

  /// Deletes a Post using the ID
  Future deletePostById(int postId) async {
    await _client.from('Posts').delete().eq('id', postId);
  }

  //TODO createPost
  //* Create Post
  Future createPost(Post newPost) async {
    return await _client.from('Posts').insert({
      'title': newPost.title,
      'description': newPost.description,
      'price': newPost.price,
      'user_id': newPost.userId
    }).select();
  }

  //* Update Post
  Future updatePost(Post post) async {
    final title = post.title;
    final description = post.description;
    final price = post.price;

    if (title.isEmpty) {
      return false;
    }

    if (description == null || description.isEmpty) {
      return false;
    }

    if (price == null || price <= 0) {
      return false;
    }

    return await _client
        .from('Posts')
        .update({
          'title': title,
          'description': description,
          'price': price,
          'is_active': post.isActive,
          'images': post.imageUrls ?? [],
        })
        .eq('id', post.id ?? 0)
        .select();
  }

  //TODO addPostToWishlist

  //TODO removePostFromWishlist
}

class Post {
  int? id;
  String title = '';
  String? description = '';
  int? price = 0;
  bool isActive = false;
  String userId;
  List<String>? imageUrls = [];

  Post({
    required this.title,
    this.id,
    this.description,
    this.price,
    required this.isActive,
    required this.userId,
    this.imageUrls,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: map['price'] ?? 0,
      isActive: map['is_active'] ?? true,
      userId: map['user_id'] ?? '',
      imageUrls: map['images'] != null
          ? List<String>.from(map['images'].map((x) => x.toString()))
          : [],
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

  Post copyWith({
    int? id,
    String? title,
    String? description,
    int? price,
    bool? isActive,
    String? userId,
    List<String>? imageUrls,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}