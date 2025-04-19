import 'dart:io';
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

  ///
  Future<String> uploadProfilePicBucket(String filePath) async {
    final avatarFile = File(filePath);
    return await _client.storage.from('profile-pics').upload(
          'public/avatar1.png',
          avatarFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
  }

  ///
  Future<String> uploadPostPicBucket(String filePath) async {
    final avatarFile = File(filePath);
    return await _client.storage.from('post-pics').upload(
          'public/avatar1.png',
          avatarFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
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
