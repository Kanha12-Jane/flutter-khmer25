import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:project_flutter_khmer25/core/api_config.dart';
import 'package:project_flutter_khmer25/models/product_model.dart';

enum ProductFilterType { newProducts, discountProducts }

class ProductProvider extends ChangeNotifier {
  // =========================
  // PAGINATION STATE (2 lists)
  // =========================
  final List<Product> _newItems = [];
  final List<Product> _discountItems = [];

  bool _loadingNew = false;
  bool _loadingDiscount = false;

  bool _loadingMoreNew = false;
  bool _loadingMoreDiscount = false;

  String? _errorNew;
  String? _errorDiscount;

  int _newPage = 1;
  int _discountPage = 1;

  bool _newHasMore = true;
  bool _discountHasMore = true;

  // =========================
  // DETAIL STATE
  // =========================
  Product? _detailProduct;
  bool _isLoadingDetail = false;
  String? _detailError;

  // ---------- getters ----------
  List<Product> get newProducts => _newItems;
  List<Product> get discountProducts => _discountItems;

  bool isLoading(ProductFilterType type) =>
      type == ProductFilterType.newProducts ? _loadingNew : _loadingDiscount;

  bool isLoadingMore(ProductFilterType type) =>
      type == ProductFilterType.newProducts
      ? _loadingMoreNew
      : _loadingMoreDiscount;

  String? error(ProductFilterType type) =>
      type == ProductFilterType.newProducts ? _errorNew : _errorDiscount;

  bool hasMore(ProductFilterType type) =>
      type == ProductFilterType.newProducts ? _newHasMore : _discountHasMore;

  Product? get detailProduct => _detailProduct;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  // =========================
  // HEADERS
  // =========================
  Map<String, String> _headers(String? accessToken) => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    if (accessToken != null && accessToken.isNotEmpty)
      "Authorization": "Bearer $accessToken",
  };

  // =========================
  // ✅ IMPORTANT:
  // Make sure these query params match your backend filters.
  //
  // If your backend doesn't support is_new / discount filters,
  // tell me your real endpoint params and I adjust it 100%.
  // =========================
  String _listUrl(ProductFilterType type, int page) {
    final base = "${ApiConfig.api}/products/";

    if (type == ProductFilterType.newProducts) {
      return "$base?is_new=true&page=$page";
    } else {
      // ✅ backend expects discounted=true
      return "$base?discounted=true&page=$page";
    }
  }

  // =========================
  // INIT / REFRESH / LOAD MORE
  // =========================
  Future<void> initFirstPage(
    ProductFilterType type, {
    String? accessToken,
  }) async {
    // if already loaded you can skip, but best to refresh once
    await refresh(type, accessToken: accessToken);
  }

  Future<void> refresh(ProductFilterType type, {String? accessToken}) async {
    if (type == ProductFilterType.newProducts) {
      _loadingNew = true;
      _loadingMoreNew = false;
      _errorNew = null;
      _newPage = 1;
      _newHasMore = true;
      _newItems.clear();
    } else {
      _loadingDiscount = true;
      _loadingMoreDiscount = false;
      _errorDiscount = null;
      _discountPage = 1;
      _discountHasMore = true;
      _discountItems.clear();
    }
    notifyListeners();

    try {
      final pageData = await _fetchPaginated(
        type,
        page: 1,
        accessToken: accessToken,
      );
      if (type == ProductFilterType.newProducts) {
        _newItems.addAll(pageData.items);
        _newHasMore = pageData.next != null;
        _newPage = 2;
      } else {
        _discountItems.addAll(pageData.items);
        _discountHasMore = pageData.next != null;
        _discountPage = 2;
      }
    } catch (e) {
      if (type == ProductFilterType.newProducts) {
        _errorNew = e.toString();
      } else {
        _errorDiscount = e.toString();
      }
      if (kDebugMode) debugPrint("refresh($type) error: $e");
    } finally {
      if (type == ProductFilterType.newProducts) {
        _loadingNew = false;
      } else {
        _loadingDiscount = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadMore(ProductFilterType type, {String? accessToken}) async {
    if (isLoading(type) || isLoadingMore(type) || !hasMore(type)) return;

    if (type == ProductFilterType.newProducts) {
      _loadingMoreNew = true;
    } else {
      _loadingMoreDiscount = true;
    }
    notifyListeners();

    try {
      final page = type == ProductFilterType.newProducts
          ? _newPage
          : _discountPage;
      final pageData = await _fetchPaginated(
        type,
        page: page,
        accessToken: accessToken,
      );

      if (type == ProductFilterType.newProducts) {
        _newItems.addAll(pageData.items);
        _newHasMore = pageData.next != null;
        _newPage = _newPage + 1;
      } else {
        _discountItems.addAll(pageData.items);
        _discountHasMore = pageData.next != null;
        _discountPage = _discountPage + 1;
      }
    } catch (e) {
      if (type == ProductFilterType.newProducts) {
        _errorNew = e.toString();
      } else {
        _errorDiscount = e.toString();
      }
      if (kDebugMode) debugPrint("loadMore($type) error: $e");
    } finally {
      if (type == ProductFilterType.newProducts) {
        _loadingMoreNew = false;
      } else {
        _loadingMoreDiscount = false;
      }
      notifyListeners();
    }
  }

  // =========================
  // NETWORK: PAGINATION
  // =========================
  Future<_PagedResult> _fetchPaginated(
    ProductFilterType type, {
    required int page,
    String? accessToken,
  }) async {
    final url = _listUrl(type, page);
    final uri = Uri.parse(url);

    final res = await http
        .get(uri, headers: _headers(accessToken))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    // DRF pagination format:
    // { count, next, previous, results: [...] }
    if (decoded is! Map<String, dynamic> || decoded["results"] is! List) {
      throw Exception("Invalid pagination format: ${decoded.runtimeType}");
    }

    final results = decoded["results"] as List;
    final next = decoded["next"] as String?;

    final items = results
        .whereType<Map<String, dynamic>>()
        .map((e) => Product.fromJson(e))
        .toList();

    return _PagedResult(items: items, next: next);
  }

  // =========================
  // DETAIL: /api/products/<id>/
  // (related_products comes from here ✅)
  // =========================
  Future<void> fetchProductDetail(int id, {String? accessToken}) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final uri = Uri.parse("${ApiConfig.api}/products/$id/");
      final res = await http
          .get(uri, headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        _detailError = "HTTP ${res.statusCode}: ${res.body}";
        _detailProduct = null;
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        _detailError = "Invalid detail format: ${decoded.runtimeType}";
        _detailProduct = null;
        return;
      }

      _detailProduct = Product.fromJson(decoded);
    } catch (e) {
      _detailError = e.toString();
      _detailProduct = null;
      if (kDebugMode) debugPrint('fetchProductDetail error: $e');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clear() {
    _newItems.clear();
    _discountItems.clear();

    _errorNew = null;
    _errorDiscount = null;

    _loadingNew = false;
    _loadingDiscount = false;

    _loadingMoreNew = false;
    _loadingMoreDiscount = false;

    _newPage = 1;
    _discountPage = 1;

    _newHasMore = true;
    _discountHasMore = true;

    _detailProduct = null;
    _detailError = null;
    _isLoadingDetail = false;

    notifyListeners();
  }
}

class _PagedResult {
  final List<Product> items;
  final String? next;
  _PagedResult({required this.items, required this.next});
}
