class OrderModel {
  final int id;
  final String orderCode;
  final num total;
  final String status;
  final DateTime? createdAt;
  final int itemsCount;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.itemsCount,
  });

  // ---------- safe parsers ----------
  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static num _asNum(dynamic v, {num fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// ✅ Map from your DRF json
  /// supports keys:
  /// id, order_code, total, status/payment_status, created_at, items_count, items
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json["id"]);
    final code = (json["order_code"] ?? json["code"] ?? "#$id").toString();

    final total = _asNum(json["total"] ?? json["amount"] ?? 0);

    final status = (json["status"] ?? json["payment_status"] ?? "pending")
        .toString()
        .toLowerCase();

    final createdAt = _asDate(
      json["created_at"] ?? json["created"] ?? json["date"],
    );

    int itemsCount = _asInt(json["items_count"]);
    if (itemsCount == 0 && json["items"] is List) {
      itemsCount = (json["items"] as List).length;
    }

    return OrderModel(
      id: id,
      orderCode: code,
      total: total,
      status: status,
      createdAt: createdAt,
      itemsCount: itemsCount,
    );
  }

  // ✅ UI helpers
  String get totalText => "${total.toStringAsFixed(0)}៛";

  String get createdAtText {
    final d = createdAt;
    if (d == null) return "";
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}-$mm-$dd";
  }
}
