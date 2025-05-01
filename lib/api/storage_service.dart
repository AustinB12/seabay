import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Reteieves the Supabase Bucket for user's profile pictures
  Future<Bucket> getProfilePicBucket() async {
    return await _client.storage.getBucket('profile-pics');
  }

  ///
  Future<Bucket> getPostPicBucket() async {
    return await _client.storage.getBucket('post-pics');
  }

  Future updateUserProfilePictureUrl(String publicUrl) async {
    await _client.from('User_Profiles').update({'profile_pic': publicUrl}).eq(
        'auth_id', _client.auth.currentUser!.id);
  }

  Future<String> getPostImageUrl(String path) async {
    return _client.storage.from('post-pics').getPublicUrl(path);
  }

  Future<String> getProfileImageUrl(String path) async {
    return _client.storage.from('profile-pics').getPublicUrl(path);
  }

  ///
  Future uploadProfilePicBucket(
      String path, Uint8List image, String? imageExtension) async {
    await _client.storage.from('profile-pics').uploadBinary(
          path,
          image,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$imageExtension',
          ),
        );
  }

  ///
  Future uploadPostPicBucket(
      String path, Uint8List image, String? imageExtension) async {
    await _client.storage.from('post-pics').uploadBinary(
          path,
          image,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$imageExtension',
          ),
        );
  }

  ///
  Future deleteProfilePicBucket(List<String> filePaths) async {
    await _client.storage.from('profile-pics').remove([...filePaths]);
  }

  ///
  Future deletePostPicBucket(List<String> filePaths) async {
    await _client.storage.from('post-pics').remove([...filePaths]);
  }
}
