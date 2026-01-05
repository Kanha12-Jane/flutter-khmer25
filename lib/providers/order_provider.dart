import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:project_flutter_khmer25/core/api_config.dart';
import 'package:project_flutter_khmer25/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  // last order created (useful after checkout)
  Map<String, dynamic>? _lastOrder;

  // raw list orders (keep for compatibility)
  List<Map<String, dynamic>> _orders = [];

  // ✅ typed list orders (for UI)
  List<OrderModel> _ordersModel = [];

  bool _isLoading = false;
  String? _error;

  // =========================
  // Getters
  // =========================
  Map<String, dynamic>? get lastOrder => _lastOrder;

  /// raw (old)
  List<Map<String, dynamic>> get orders => _orders;

  /// ✅ new typed list
  List<OrderModel> get ordersModel => _ordersModel;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // =========================
  // Headers (same style as CartProvider)
  // =========================
  Map<String, String> _headers(String? accessToken) => {
    "Content-Type": "application/json",
    if (accessToken != null && accessToken.isNotEmpty)
      "Authorization": "Bearer $accessToken",
  };

  Map<String, String> _authOnlyHeaders(String? accessToken) => {
    if (accessToken != null && accessToken.isNotEmpty)
      "Authorization": "Bearer $accessToken",
    "Accept": "application/json",
  };

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // =========================
  // POST /api/orders/checkout/
  // body: {phone, address, note}
  // return: order json
  // =========================
  Future<Map<String, dynamic>?> checkout({
    required String phone,
    required String address,
    String note = "",
    required String? accessToken,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final uri = Uri.parse("${ApiConfig.api}/orders/checkout/");

      final res = await http
          .post(
            uri,
            headers: _headers(accessToken),
            body: jsonEncode({
              "phone": phone,
              "address": address,
              "note": note,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        _lastOrder = data;
        notifyListeners();
        return data;
      } else {
        _error = "Checkout failed (${res.statusCode})\n${res.body}";
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print("OrderProvider checkout error: $e");
      }
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // POST /api/orders/<id>/upload-proof/
  // multipart: image + note
  // =========================
  Future<bool> uploadProof({
    required int orderId,
    required Uint8List bytes,
    required String filename,
    String note = "",
    required String? accessToken,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final uri = Uri.parse("${ApiConfig.api}/orders/$orderId/upload-proof/");

      final req = http.MultipartRequest("POST", uri);
      req.headers.addAll(
        _authOnlyHeaders(accessToken),
      ); // ✅ no Content-Type json
      req.fields["note"] = note;

      req.files.add(
        http.MultipartFile.fromBytes("image", bytes, filename: filename),
      );

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return true;
      } else {
        _error = "Upload failed (${streamed.statusCode})\n$body";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print("OrderProvider uploadProof error: $e");
      }
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // GET /api/orders/
  // return: list orders
  // =========================
  Future<void> fetchMyOrders({required String? accessToken}) async {
    _setLoading(true);
    _error = null;

    try {
      final uri = Uri.parse("${ApiConfig.api}/orders/");

      final res = await http
          .get(uri, headers: _authOnlyHeaders(accessToken))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);

        // DRF pagination? handle both list and {results: []}
        if (raw is Map && raw["results"] is List) {
          _orders = (raw["results"] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else if (raw is List) {
          _orders = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _orders = [];
        }

        // ✅ map raw -> model list
        _ordersModel = _orders.map((e) => OrderModel.fromJson(e)).toList();

        notifyListeners();
      } else {
        _error = "Load orders failed (${res.statusCode})\n${res.body}";
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print("OrderProvider fetchMyOrders error: $e");
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // GET /api/orders/<id>/
  // return: order detail json (raw)
  // =========================
  Future<Map<String, dynamic>?> fetchOrderDetail({
    required int orderId,
    required String? accessToken,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final uri = Uri.parse("${ApiConfig.api}/orders/$orderId/");

      final res = await http
          .get(uri, headers: _authOnlyHeaders(accessToken))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(res.body));
        return data;
      } else {
        _error = "Load order detail failed (${res.statusCode})\n${res.body}";
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print("OrderProvider fetchOrderDetail error: $e");
      }
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // =========================
  // Clear
  // =========================
  void clear() {
    _lastOrder = null;
    _orders = [];
    _ordersModel = [];
    _error = null;
    notifyListeners();
  }
}
