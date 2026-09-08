import 'package:shared_preferences/shared_preferences.dart';

/// Stores/retrieves MySQL connection settings, mirroring the original
/// app's PriceSettingsPage (host / port / username / password / dbname).
class SettingsService {
  static const _kHost = 'db_host';
  static const _kPort = 'db_port';
  static const _kUser = 'db_user';
  static const _kPassword = 'db_password';
  static const _kDbName = 'db_name';

  Future<Map<String, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'host': prefs.getString(_kHost) ?? '',
      'port': prefs.getString(_kPort) ?? '3306',
      'user': prefs.getString(_kUser) ?? '',
      'password': prefs.getString(_kPassword) ?? '',
      'dbname': prefs.getString(_kDbName) ?? '',
    };
  }

  Future<void> saveAll({
    required String host,
    required String port,
    required String user,
    required String password,
    required String dbname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHost, host);
    await prefs.setString(_kPort, port);
    await prefs.setString(_kUser, user);
    await prefs.setString(_kPassword, password);
    await prefs.setString(_kDbName, dbname);
  }

  Future<bool> isConfigured() async {
    final s = await loadAll();
    return s['host']!.isNotEmpty && s['dbname']!.isNotEmpty;
  }
}
