import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/constants/preview_auth.dart';

class TokenStorage {
  Future<void> saveToken(String token, String role, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_role', role);
    await prefs.setString('user_id', userId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (!PreviewAuth.enabled && token == PreviewAuth.token) return null;
    return token;
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
  }
}
