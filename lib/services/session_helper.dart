import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SessionData {
  final bool loggedIn;
  final String? role;
  final String? nik;
  final String? nama;

  const SessionData({
    required this.loggedIn,
    required this.role,
    required this.nik,
    required this.nama,
  });

  const SessionData.signedOut()
      : loggedIn = false,
        role = null,
        nik = null,
        nama = null;

  bool get isAdmin {
    return loggedIn && role == SessionHelper.adminRole;
  }

  bool get isUser {
    return loggedIn &&
        role == SessionHelper.userRole &&
        (nik?.trim().isNotEmpty ?? false) &&
        (nama?.trim().isNotEmpty ?? false);
  }

  bool get isValid => isAdmin || isUser;
}

class SessionHelper {
  static const String adminRole = 'admin';
  static const String userRole = 'user';

  /*
   * Semua data sesi disimpan dalam satu JSON agar role, NIK,
   * dan nama tidak terpisah-pisah saat aplikasi ditutup.
   */
  static const String _sessionKey = 'tanigo_session_v2';

  /*
   * Key lama tetap dibaca agar pengguna yang sudah pernah login
   * tidak langsung dianggap keluar setelah pembaruan aplikasi.
   */
  static const String _legacyRoleKey = 'login_role';
  static const String _legacyNikKey = 'login_nik';
  static const String _legacyNamaKey = 'login_nama';

  static Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  static Future<void> saveUserSession({
    required String nik,
    required String nama,
  }) async {
    final cleanNik = nik.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final cleanNama = nama.trim();

    if (cleanNik.isEmpty || cleanNama.isEmpty) {
      throw StateError(
        'Sesi pengguna tidak dapat disimpan karena data tidak lengkap.',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    final payload = jsonEncode({
      'logged_in': true,
      'role': userRole,
      'nik': cleanNik,
      'nama': cleanNama,
      'saved_at': DateTime.now().toIso8601String(),
    });

    final saved = await prefs.setString(
      _sessionKey,
      payload,
    );

    if (!saved) {
      throw StateError('Gagal menyimpan sesi pengguna.');
    }

    /*
     * Key lama ikut diperbarui sebagai cadangan kompatibilitas.
     */
    await prefs.setString(_legacyRoleKey, userRole);
    await prefs.setString(_legacyNikKey, cleanNik);
    await prefs.setString(_legacyNamaKey, cleanNama);
  }

  static Future<void> saveAdminSession() async {
    final prefs = await SharedPreferences.getInstance();

    final payload = jsonEncode({
      'logged_in': true,
      'role': adminRole,
      'saved_at': DateTime.now().toIso8601String(),
    });

    final saved = await prefs.setString(
      _sessionKey,
      payload,
    );

    if (!saved) {
      throw StateError('Gagal menyimpan sesi admin.');
    }

    await prefs.setString(_legacyRoleKey, adminRole);
    await prefs.remove(_legacyNikKey);
    await prefs.remove(_legacyNamaKey);
  }

  static Future<SessionData> getSession() async {
    final prefs = await _prefs();

    final raw = prefs.getString(_sessionKey);

    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map) {
          final data = Map<String, dynamic>.from(
            decoded.map(
              (key, value) => MapEntry(
                key.toString(),
                value,
              ),
            ),
          );

          final loggedIn = data['logged_in'] == true;
          final role = data['role']?.toString().trim();
          final nik = data['nik']?.toString().trim();
          final nama = data['nama']?.toString().trim();

          final session = SessionData(
            loggedIn: loggedIn,
            role: role,
            nik: nik,
            nama: nama,
          );

          if (session.isValid) {
            return session;
          }
        }
      } catch (_) {
        /*
         * JSON rusak akan dilanjutkan ke migrasi key lama.
         */
      }
    }

    return _readAndMigrateLegacySession(prefs);
  }

  static Future<SessionData> _readAndMigrateLegacySession(
    SharedPreferences prefs,
  ) async {
    final role = prefs
        .getString(_legacyRoleKey)
        ?.trim()
        .toLowerCase();

    if (role == adminRole) {
      await saveAdminSession();

      return const SessionData(
        loggedIn: true,
        role: adminRole,
        nik: null,
        nama: null,
      );
    }

    if (role == userRole) {
      final nik = prefs.getString(_legacyNikKey)?.trim();
      final nama = prefs.getString(_legacyNamaKey)?.trim();

      if ((nik?.isNotEmpty ?? false) &&
          (nama?.isNotEmpty ?? false)) {
        await saveUserSession(
          nik: nik!,
          nama: nama!,
        );

        return SessionData(
          loggedIn: true,
          role: userRole,
          nik: nik,
          nama: nama,
        );
      }
    }

    return const SessionData.signedOut();
  }

  static Future<String?> getRole() async {
    final session = await getSession();
    return session.role;
  }

  static Future<String?> getNik() async {
    final session = await getSession();
    return session.nik;
  }

  static Future<String?> getNama() async {
    final session = await getSession();
    return session.nama;
  }

  static Future<bool> hasValidSession() async {
    final session = await getSession();
    return session.isValid;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_sessionKey);
    await prefs.remove(_legacyRoleKey);
    await prefs.remove(_legacyNikKey);
    await prefs.remove(_legacyNamaKey);
  }
}
