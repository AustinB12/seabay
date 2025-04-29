class SeabayUser {
  int? id;
  String? authId;
  String firstName;
  String lastName;
  String? profilePictureUrl;

  SeabayUser(
      {this.id,
      required this.firstName,
      required this.lastName,
      this.authId,
      this.profilePictureUrl});

  factory SeabayUser.fromMap(Map<String, dynamic> map) {
    return SeabayUser(
        id: map['id'] as int,
        authId: map['auth_id'] as String,
        firstName: map['first_name'] ?? '',
        lastName: map['last_name'] ?? '',
        profilePictureUrl: map['profile_pic']);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authId': authId,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
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
