import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_config.dart';
import 'auth_provider.dart';

class PickedImageBytes {
  final Uint8List bytes;
  final String name;
  PickedImageBytes({required this.bytes, required this.name});
}

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _me;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get me => _me;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? e) {
    _error = e;
    notifyListeners();
  }

  Map<String, String> _bearerHeaders(String token) => {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

  Map<String, String> _bearerJsonHeaders(String token) => {
        ..._bearerHeaders(token),
        "Content-Type": "application/json",
      };

  String? get imageUrl {
    final profile = _me?["profile"];
    if (profile is Map<String, dynamic>) {
      final url = profile["image_url"];
      if (url is String && url.isNotEmpty) {
        if (url.startsWith("http://") || url.startsWith("https://")) return url;
        final base = ApiConfig.host;
        if (url.startsWith("/")) return "$base$url";
        return "$base/$url";
      }
    }
    return null;
  }

  Future<String?> _token(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final t = await auth.getValidAccessToken();
    if (t == null || t.isEmpty) {
      _setError("Session expired. Please login again.");
      return null;
    }
    return t;
  }

  // -------------------------
  // GET /api/users/me/
  // -------------------------
  Future<void> loadMe(BuildContext context) async {
    final token = await _token(context);
    if (token == null) return;

    _setLoading(true);
    _setError(null);

    try {
      final uri = Uri.parse("${ApiConfig.api}/users/me/");
      final res = await http
          .get(uri, headers: _bearerHeaders(token))
          .timeout(const Duration(seconds: 12));

      if (kDebugMode) {
        print("GET /api/users/me => ${res.statusCode}");
        if (res.statusCode != 200) print("body => ${res.body}");
      }

      if (res.statusCode == 200) {
        _me = jsonDecode(res.body) as Map<String, dynamic>;
        await loadProfile(context);
      } else {
        _setError(_parseError(res));
      }
    } catch (e) {
      _setError("loadMe error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------
  // GET /api/users/profile/
  // returns {image, image_url}
  // -------------------------
  Future<void> loadProfile(BuildContext context) async {
    final token = await _token(context);
    if (token == null) return;

    try {
      final uri = Uri.parse("${ApiConfig.api}/users/profile/");
      final res = await http
          .get(uri, headers: _bearerHeaders(token))
          .timeout(const Duration(seconds: 12));

      if (kDebugMode) {
        print("GET /api/users/profile => ${res.statusCode}");
        if (res.statusCode != 200) print("body => ${res.body}");
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          final url = (data["image_url"] ?? data["image"])?.toString() ?? "";
          _me ??= {};
          _me!["profile"] ??= <String, dynamic>{};
          (_me!["profile"] as Map<String, dynamic>)["image_url"] = url;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) print("loadProfile error: $e");
    }
  }

  // -------------------------
  // PATCH /api/users/me/
  // body: {"username": "..."}
  // -------------------------
  Future<bool> updateUsername(BuildContext context, String username) async {
    final token = await _token(context);
    if (token == null) return false;

    final newName = username.trim();
    if (newName.isEmpty) {
      _setError("Username required.");
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final uri = Uri.parse("${ApiConfig.api}/users/me/");
      final res = await http
          .patch(
            uri,
            headers: _bearerJsonHeaders(token),
            body: jsonEncode({"username": newName}),
          )
          .timeout(const Duration(seconds: 12));

      if (kDebugMode) {
        print("PATCH /api/users/me => ${res.statusCode}");
        print("body => ${res.body}");
      }

      if (res.statusCode == 200) {
        _me = jsonDecode(res.body) as Map<String, dynamic>;
        notifyListeners();
        return true;
      }

      _setError(_parseError(res));
      return false;
    } catch (e) {
      _setError("updateUsername error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // -------------------------
  // Pick image (WEB + MOBILE)
  // -------------------------
  Future<PickedImageBytes?> pickImageBytes() async {
    try {
      _setError(null);
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return null;

      final bytes = await x.readAsBytes();
      final name = x.name.isNotEmpty ? x.name : "profile.jpg";
      return PickedImageBytes(bytes: bytes, name: name);
    } catch (e) {
      _setError("Pick image error: $e");
      return null;
    }
  }

  // -------------------------
  // PATCH /api/users/profile/image/
  // field: image
  // WEB + MOBILE using bytes
  // -------------------------
  Future<bool> uploadProfileImageBytes(
    BuildContext context, {
    required Uint8List bytes,
    required String filename,
  }) async {
    final token = await _token(context);
    if (token == null) return false;

    _setLoading(true);
    _setError(null);

    try {
      final uri = Uri.parse("${ApiConfig.api}/users/profile/image/");
      final req = http.MultipartRequest("PATCH", uri);

      req.headers["Accept"] = "application/json";
      req.headers["Authorization"] = "Bearer $token";

      req.files.add(
        http.MultipartFile.fromBytes(
          "image",
          bytes,
          filename: filename,
        ),
      );

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      if (kDebugMode) {
        print("PATCH /api/users/profile/image => ${streamed.statusCode}");
        print("body => $body");
      }

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        await loadMe(context);
        return true;
      }

      _setError("Upload failed (${streamed.statusCode})\n$body");
      return false;
    } catch (e) {
      _setError("uploadProfileImage error: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _parseError(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        if (data["detail"] != null) return data["detail"].toString();

        for (final k in ["username", "image", "non_field_errors"]) {
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

  void clear() {
    _me = null;
    _error = null;
    notifyListeners();
  }
}
