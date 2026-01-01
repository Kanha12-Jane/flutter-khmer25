import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:project_flutter_khmer25/providers/auth_provider.dart';
import 'package:project_flutter_khmer25/providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      Future.microtask(() {
        context.read<CartProvider>().fetchCart(accessToken: auth.access);
      });
    }
  }

  // ✅ sample PayWay link builder
  // Best practice: your backend should generate this link securely.
  String _buildPayWayLink({required double amount}) {
    final amt = amount.toStringAsFixed(0);
    return "https://link.payway.com.kh/aba?id=FA16B4CB56DF&dynamic=true&source_caller=sdk&pid=af_app_invites&link_action=abaqr&shortlink=qi6y4hz0&amount=$amt&created_from_app=true&acc=012333176&af_siteid=968860649&userid=FA16B4CB56DF&code=719145&c=abaqr&af_referrer_uid=1760314176853-4531428";
  }

  Future<_ShippingInfo?> _openShippingSheet(BuildContext context) async {
    return showModalBottomSheet<_ShippingInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ShippingBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cartProv = context.watch<CartProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("កន្ត្រក")),
        body: const Center(child: Text("សូម Login មុន ដើម្បីមើលកន្ត្រក 🙏")),
      );
    }

    final cart = cartProv.cart;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text("កន្ត្រក"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => cartProv.fetchCart(accessToken: auth.access),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cartProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartProv.error != null
          ? _ErrorBox(
              message: cartProv.error!,
              onRetry: () => cartProv.fetchCart(accessToken: auth.access),
            )
          : (cart == null || cart.items.isEmpty)
          ? const _EmptyCart()
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 160),
              children: [
                _SummaryHeader(
                  totalItems: cart.totalQty,
                  totalPriceText: "${_fmt(cartProv.totalPrice)}៛",
                ),
                const SizedBox(height: 10),
                ...cart.items.map(
                  (it) => _CartItemCard(
                    itemId: it.id,
                    name: it.product.name,
                    image: it.product.image,
                    priceText: it.product.priceText,
                    qty: it.qty,
                    onMinus: () async {
                      if (it.qty <= 1) return;
                      await cartProv.updateQty(
                        cartItemId: it.id,
                        qty: it.qty - 1,
                        accessToken: auth.access,
                      );
                    },
                    onPlus: () async {
                      await cartProv.updateQty(
                        cartItemId: it.id,
                        qty: it.qty + 1,
                        accessToken: auth.access,
                      );
                    },
                    onRemove: () async {
                      await cartProv.removeItem(
                        cartItemId: it.id,
                        accessToken: auth.access,
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: (cart == null || cart.items.isEmpty)
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TotalBox(
                        totalItems: cart.totalQty,
                        totalPriceText: "${_fmt(cartProv.totalPrice)}៛",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          // 1) ask shipping info (address + phone)
                          final info = await _openShippingSheet(context);
                          if (info == null) return; // user canceled

                          // (optional) show quick confirm
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "បានរក្សាទុក ✅ ${info.phone} • ${info.shortAddress}",
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          // 2) open PayWay hosted QR page
                          final payUrl = _buildPayWayLink(
                            amount: cartProv.totalPrice,
                          );

                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PayWayCheckoutPage(
                                payUrl: payUrl,
                                title: "ទូទាត់តាម ABA KHQR",
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Checkout",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/* ===================== SHIPPING BOTTOM SHEET ===================== */

class _ShippingInfo {
  final String phone;
  final String address;
  final String note;

  const _ShippingInfo({
    required this.phone,
    required this.address,
    required this.note,
  });

  String get shortAddress {
    if (address.length <= 28) return address;
    return "${address.substring(0, 28)}…";
  }
}

class _ShippingBottomSheet extends StatefulWidget {
  const _ShippingBottomSheet();

  @override
  State<_ShippingBottomSheet> createState() => _ShippingBottomSheetState();
}

class _ShippingBottomSheetState extends State<_ShippingBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "សូមបញ្ចូលលេខទូរស័ព្ទ";
    // simple KH phone check (8-10 digits), allow +855 and spaces
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 8 || digits.length > 12) {
      return "លេខទូរស័ព្ទមិនត្រឹមត្រូវ";
    }
    return null;
  }

  String? _validateAddress(String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "សូមបញ្ចូលអាសយដ្ឋានដឹកជញ្ជូន";
    if (s.length < 6) return "សូមបញ្ចូលអាសយដ្ឋានឲ្យលម្អិតបន្តិច";
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    // simulate save (you can call backend here)
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() => _saving = false);

    Navigator.pop(
      context,
      _ShippingInfo(
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // handle
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.10),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "ព័ត៌មានដឹកជញ្ជូន",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _PrettyField(
                        label: "លេខទូរស័ព្ទ",
                        hint: "ឧ: 012 345 678",
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_iphone,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 10),
                      _PrettyField(
                        label: "អាសយដ្ឋាន",
                        hint: "ភូមិ/ឃុំ/សង្កាត់/ខណ្ឌ/ខេត្ត…",
                        controller: _addressCtrl,
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2,
                        prefixIcon: Icons.location_on_outlined,
                        validator: _validateAddress,
                      ),
                      const SizedBox(height: 10),
                      _PrettyField(
                        label: "ចំណាំ (ជម្រើស)",
                        hint: "ឧ: ទុកនៅមុខផ្ទះ / ទូរស័ព្ទមុនមក…",
                        controller: _noteCtrl,
                        keyboardType: TextInputType.text,
                        maxLines: 2,
                        prefixIcon: Icons.notes_outlined,
                        validator: (_) => null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          "បោះបង់",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "បន្តទៅទូទាត់",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrettyField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData prefixIcon;
  final String? Function(String?) validator;

  const _PrettyField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
    required this.prefixIcon,
    required this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF7F7FB),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
            ),
            child: Icon(
              prefixIcon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== PAYWAY WEBVIEW ===================== */

class PayWayCheckoutPage extends StatefulWidget {
  final String payUrl;
  final String title;

  const PayWayCheckoutPage({
    super.key,
    required this.payUrl,
    this.title = "Checkout",
  });

  @override
  State<PayWayCheckoutPage> createState() => _PayWayCheckoutPageState();
}

class _PayWayCheckoutPageState extends State<PayWayCheckoutPage> {
  bool _loading = true;

  bool _isExternalScheme(Uri u) {
    final s = u.scheme.toLowerCase();
    return s == 'intent' ||
        s == 'aba' ||
        s == 'market' ||
        s == 'tel' ||
        s == 'mailto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Reload",
            onPressed: () async {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PayWayCheckoutPage(
                    payUrl: widget.payUrl,
                    title: widget.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.payUrl)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              transparentBackground: false,
              supportZoom: false,
              useShouldOverrideUrlLoading: true,
            ),
            onLoadStart: (_, __) {
              if (mounted) setState(() => _loading = true);
            },
            onLoadStop: (_, __) {
              if (mounted) setState(() => _loading = false);
            },
            shouldOverrideUrlLoading: (controller, navAction) async {
              final uri = navAction.request.url?.uriValue;
              if (uri == null) return NavigationActionPolicy.ALLOW;

              if (_isExternalScheme(uri)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Staying in app ✅ (ABA app link blocked)"),
                    duration: Duration(seconds: 1),
                  ),
                );
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onReceivedError: (_, __, ___) {
              if (mounted) setState(() => _loading = false);
            },
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.65),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

/* ===================== CART UI WIDGETS ===================== */

class _SummaryHeader extends StatelessWidget {
  final int totalItems;
  final String totalPriceText;

  const _SummaryHeader({
    required this.totalItems,
    required this.totalPriceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "សរុបក្នុងកន្ត្រក",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$totalItems items • $totalPriceText",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBox extends StatelessWidget {
  final int totalItems;
  final String totalPriceText;

  const _TotalBox({required this.totalItems, required this.totalPriceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF7F7FB),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "សរុប ($totalItems items)",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalPriceText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final int itemId;
  final String name;
  final String? image;
  final String priceText;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.itemId,
    required this.name,
    required this.image,
    required this.priceText,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Image.network(
                image ?? "",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: onMinus,
                      disabled: qty <= 1,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF7F7FB),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        "$qty",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _QtyButton(icon: Icons.add, onTap: onPlus),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              const Text(
                "កន្ត្រកទទេ 😅",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "សូមជ្រើសរើសផលិតផល បន្ថែមចូលកន្ត្រក",
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("សាកម្តងទៀត"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmt(double v) => v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
