import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

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
}
