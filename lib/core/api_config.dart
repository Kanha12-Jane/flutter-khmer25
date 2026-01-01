class ApiConfig {
  static const host = "https://django-khmer25-production.up.railway.app/"; // ✅ ONE IP
  static const api = "$host/api";
  static const auth = "$host/auth";
  static const String categories = "$api/categories/";
  static const String products = "$api/products/";
  static String toUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    return "$host$path";
  }
}
