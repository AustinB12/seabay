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
