import 'package:seabay_app/api/types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  static String? get currentUserId =>
      Supabase.instance.client.auth.currentSession?.user.id;

  Future<AuthResponse> signInWithEmailPassword(
      String email, String password) async {
    return await _client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<String?> signUpWithEmailPassword(String email, String password) async {
    AuthResponse response =
        await _client.auth.signUp(email: email, password: password);
    if (response.user != null) {
      return response.user?.id;
    }
    return null;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? getCurrentUserEmail() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  String? getCurrentUserId() {
    final session = _client.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }

  Future<SeabayUser> getCurrentUserProfile() async {
    final results = await _client
        .from('User_Profiles')
        .select('id, first_name, last_name, auth_id')
        .eq('auth_id', currentUserId ?? '');

    return SeabayUser.fromMap(results.first);
  }

  Future<void> createNewUserProfile({
    required String authId,
    required String firstName,
    required String lastName,
  }) async {
    await _client.from('User_Profiles').insert({
      'auth_id': authId,
      'first_name': firstName,
      'last_name': lastName,
    });
  }

  Future updateUserProfile(SeabayUser user) async {
    await _client
        .from('User_Profiles')
        .update({'first_name': user.firstName, 'last_name': user.lastName}).eq(
            'auth_id', currentUserId ?? '');
  }
}
