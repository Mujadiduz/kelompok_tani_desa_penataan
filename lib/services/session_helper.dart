import 'package:shared_preferences/shared_preferences.dart';

class SessionHelper {
  static const String _roleKey = 'login_role';
  static const String _nikKey = 'login_nik';
  static const String _namaKey = 'login_nama';

  static Future<void> saveUserSession({
    required String nik,
    required String nama,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'user');
    await prefs.setString(_nikKey, nik);
    await prefs.setString(_namaKey, nama);
  }

  static Future<void> saveAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, 'admin');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getNik() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nikKey);
  }

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_namaKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_nikKey);
    await prefs.remove(_namaKey);
  }
}
