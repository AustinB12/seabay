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

