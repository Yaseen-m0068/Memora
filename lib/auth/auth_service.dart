import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String email;
  const AuthUser(this.email);
}

class AuthService {
  static const _kUsers = 'memora.users'; // json map: email -> {salt, hash}
  static const _kCurrent = 'memora.currentUser';

  Future<Map<String, dynamic>> _loadUsers() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kUsers);
    return raw == null ? {} : (jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUsers, jsonEncode(users));
  }

  String _genSalt([int len = 16]) {
    final r = Random.secure();
    final bytes = List<int>.generate(len, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hash(String password, String salt) {
    final h = sha256.convert(utf8.encode('$salt::$password'));
    return h.toString();
  }

  Future<AuthUser?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    final email = sp.getString(_kCurrent);
    if (email == null) return null;
    return AuthUser(email);
  }

  Future<void> _setCurrent(String? email) async {
    final sp = await SharedPreferences.getInstance();
    if (email == null) {
      await sp.remove(_kCurrent);
    } else {
      await sp.setString(_kCurrent, email);
    }
  }

  Future<String?> register(String email, String password) async {
    email = email.trim().toLowerCase();
    if (email.isEmpty || password.length < 6) {
      return 'Enter a valid email and a password with at least 6 characters.';
    }
    final users = await _loadUsers();
    if (users.containsKey(email)) {
      return 'This email is already registered. Please log in.';
    }
    final salt = _genSalt();
    final hash = _hash(password, salt);
    users[email] = {'salt': salt, 'hash': hash};
    await _saveUsers(users);
    await _setCurrent(email);
    return null; // success
  }

  Future<String?> login(String email, String password) async {
    email = email.trim().toLowerCase();
    final users = await _loadUsers();
    final u = users[email];
    if (u == null) return 'No account found for this email.';
    final salt = u['salt'] as String;
    final good = u['hash'] as String;
    final tryHash = _hash(password, salt);
    if (tryHash != good) return 'Incorrect password.';
    await _setCurrent(email);
    return null;
  }

  Future<void> logout() => _setCurrent(null);
}
