import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  String? access;
  String? refresh;
  Map<String, dynamic>? me;

  bool get isLoggedIn => (access ?? "").isNotEmpty;
  String? get accessToken => access;

  Map<String, String> _bearerHeaders(String token) => {
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  };

  Map<String, String> _jsonHeaders() => {
    "Accept": "application/json",
    "Content-Type": "application/json",
  };

  // =========================
  // Storage
  // =========================
  Future<void> loadFromStorageAndMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      access = prefs.getString("access");
      refresh = prefs.getString("refresh");
      notifyListeners();

      if (isLoggedIn && me == null) {
        await getMe();
      }
    } catch (e) {
      error = "Storage error: $e";
      notifyListeners();
    }
  }

  Future<void> _saveTokens(String newAccess, String newRefresh) async {
    access = newAccess;
    refresh = newRefresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access", newAccess);
    await prefs.setString("refresh", newRefresh);
    notifyListeners();
  }

  Future<void> _saveAccessOnly(String newAccess) async {
    access = newAccess;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access", newAccess);
    notifyListeners();
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access");
    await prefs.remove("refresh");
    access = null;
    refresh = null;
    me = null;
    error = null;
  }

  // =========================
  // ✅ Register (Djoser)
  // POST /auth/users/
  // =========================
  Future<bool> register(
    String username,
    String password,
    String rePassword,
  ) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse("${ApiConfig.auth}/users/"),
            headers: _jsonHeaders(),
            body: jsonEncode({
              "username": username,
              "password": password,
              "re_password": rePassword, // ✅ Djoser confirm key
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 201) {
        error = null;
        return true;
      }

      error = _parseError(res);
      return false;
    } catch (e) {
      error = "Network error: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // ✅ Login (JWT Create)
  // POST /auth/jwt/create/
  // =========================
  Future<bool> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse("${ApiConfig.auth}/jwt/create/"),
            headers: _jsonHeaders(),
            body: jsonEncode({"username": username, "password": password}),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        await _clearSession();
        error = _parseError(res);
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newAccess = data["access"] as String?;
      final newRefresh = data["refresh"] as String?;

      if ((newAccess ?? "").isEmpty || (newRefresh ?? "").isEmpty) {
        error = "Login success but token missing!";
        return false;
      }

      await _saveTokens(newAccess!, newRefresh!);

      // load djoser me (optional)
      await getMe();
      return true;
    } catch (e) {
      error = "Network error: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // Refresh Access Token
  // POST /auth/jwt/refresh/
  // =========================
  Future<bool> refreshAccess() async {
    if ((refresh ?? "").isEmpty) return false;

    try {
      final res = await http
          .post(
            Uri.parse("${ApiConfig.auth}/jwt/refresh/"),
            headers: _jsonHeaders(),
            body: jsonEncode({"refresh": refresh}),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newAccess = data["access"] as String?;
      if ((newAccess ?? "").isEmpty) return false;

      await _saveAccessOnly(newAccess!);
      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // ✅ return valid access token
  // =========================
  Future<String?> getValidAccessToken() async {
    if (!isLoggedIn) return null;

    // quick verify with Djoser me
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.auth}/users/me/"),
        headers: _bearerHeaders(access!),
      );

      if (res.statusCode == 200) return access;

      if (res.statusCode == 401) {
        final ok = await refreshAccess();
        if (!ok) return null;
        return access;
      }

      return access;
    } catch (_) {
      // if offline, still return it
      return access;
    }
  }

  // =========================
  // GET Djoser me (optional)
  // GET /auth/users/me/
  // =========================
  Future<bool> getMe() async {
    final token = await getValidAccessToken();
    if (token == null) return false;

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.auth}/users/me/"),
        headers: _bearerHeaders(token),
      );

      if (res.statusCode == 200) {
        me = jsonDecode(res.body) as Map<String, dynamic>;
        error = null;
        notifyListeners();
        return true;
      }

      if (res.statusCode == 401) {
        await logout();
        return false;
      }

      error = _parseError(res);
      return false;
    } catch (e) {
      error = "GetMe error: $e";
      return false;
    } finally {
      notifyListeners();
    }
  }

  // =========================
  // Logout
  // =========================
  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  // =========================
  // Error parser
  // =========================
  String _parseError(http.Response res) {
    try {
      final data = jsonDecode(res.body);

      if (data is Map<String, dynamic>) {
        if (data["detail"] != null) return data["detail"].toString();

        for (final k in [
          "username",
          "password",
          "re_password",
          "non_field_errors",
        ]) {
          final v = data[k];
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String && v.isNotEmpty) return v;
        }

        return data.entries.map((e) => "${e.key}: ${e.value}").join("\n");
      }

      return res.body;
    } catch (_) {
      return "Request failed (${res.statusCode})";
    }
  }
}
