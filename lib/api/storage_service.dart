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

  Future<String> getPostImageUrl(String path) async {
    return _client.storage.from('post-pics').getPublicUrl(path);
  }

  ///
  Future<String> uploadProfilePicBucket(String filePath) async {
    final avatarFile = File(filePath);
    return await _client.storage.from('profile-pics').upload(
          '${_client.auth.currentUser?.id}/${filePath}',
          avatarFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
  }

  ///
  Future uploadPostPicBucket(
      String path, Uint8List image, String? imageExtension) async {
    print('\n\n\n');
    print(path);
    print('\n\n\n');
    print(imageExtension);
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
