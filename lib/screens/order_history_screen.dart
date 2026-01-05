import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_flutter_khmer25/providers/auth_provider.dart';
import 'package:project_flutter_khmer25/providers/order_provider.dart';
import 'package:project_flutter_khmer25/models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _inited = false;
  String _filter = "all"; // all, pending, paid, cancel, deliver

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      Future.microtask(() {
        context.read<OrderProvider>().fetchMyOrders(accessToken: auth.access);
      });
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    await context.read<OrderProvider>().fetchMyOrders(accessToken: auth.access);
  }

  List<OrderModel> _applyFilter(List<OrderModel> list) {
    final s = _filter.toLowerCase();
    if (s == "all") return list;

    return list.where((o) {
      final st = o.status.toLowerCase();
      if (s == "paid") return st.contains("paid") || st.contains("success");
      if (s == "pending") return st.contains("pending") || st.contains("wait");
      if (s == "cancel") return st.contains("cancel") || st.contains("reject");
      if (s == "deliver") return st.contains("deliver") || st.contains("ship");
      return st.contains(s);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        appBar: AppBar(
          title: const Text("ប្រវត្តិបញ្ជាទិញ"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: const [
              SizedBox(height: 80),
              _CenterMessageLight(
                icon: Icons.lock_outline,
                title: "សូម Login មុន 🙏",
                subtitle: "ដើម្បីមើលប្រវត្តិបញ្ជាទិញរបស់អ្នក",
              ),
            ],
          ),
        ),
      );
    }

    final allOrders = orderProv.ordersModel;
    final orders = _applyFilter(allOrders);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        title: const Text("ប្រវត្តិបញ្ជាទិញ"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: orderProv.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SafeArea(
        bottom: true, // ✅ prevents bottom overflow
        child: Column(
          children: [
            const SizedBox(height: 10),
            _FilterChipsLight(
              value: _filter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _buildBody(orderProv, allOrders, orders),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    OrderProvider orderProv,
    List<OrderModel> allOrders,
    List<OrderModel> orders,
  ) {
    // ✅ Always return a scrollable widget (fix overflow + refresh works)
    if (orderProv.isLoading) {
      return const _LoadingListLight();
    }

    if (orderProv.error != null) {
      return _ErrorBoxLight(message: orderProv.error!, onRetry: _refresh);
    }

    if (allOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: const [
          SizedBox(height: 80),
          _CenterMessageLight(
            icon: Icons.receipt_long_outlined,
            title: "មិនទាន់មានបញ្ជាទិញទេ 😅",
            subtitle: "ពេលអ្នក Checkout បញ្ជាទិញរបស់អ្នកនឹងបង្ហាញនៅទីនេះ",
          ),
        ],
      );
    }

    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: const [
          SizedBox(height: 80),
          _CenterMessageLight(
            icon: Icons.filter_alt_off,
            title: "មិនមាន Order តាម Filter នេះទេ",
            subtitle: "សូមសាក filter ផ្សេងទៀត",
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 22), // ✅ bottom padding
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final o = orders[i];
        final code = o.orderCode.isNotEmpty ? o.orderCode : "#${o.id}";

        return _OrderCardLight(
          code: code,
          createdAtText: o.createdAtText.isEmpty ? "—" : o.createdAtText,
          amountText: o.totalText,
          status: o.status,
          itemsCount: o.itemsCount,
          onTap: () {},
        );
      },
    );
  }
}

/* ===================== FILTER CHIPS (LIGHT) ===================== */

class _FilterChipsLight extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterChipsLight({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ("all", "All"),
      ("pending", "Pending"),
      ("paid", "Paid"),
      ("cancel", "Cancel"),
      ("deliver", "Deliver"),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: items.map((it) {
          final selected = value == it.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                it.$2,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              selected: selected,
              onSelected: (_) => onChanged(it.$1),
              showCheckmark: false,
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.14),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/* ===================== ORDER CARD (LIGHT) ===================== */

class _OrderCardLight extends StatelessWidget {
  final String code;
  final String createdAtText;
  final String amountText;
  final String status;
  final int itemsCount;
  final VoidCallback onTap;

  const _OrderCardLight({
    required this.code,
    required this.createdAtText,
    required this.amountText,
    required this.status,
    required this.itemsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.10),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAtText,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChipLight(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF7F7FB),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniInfoLight(
                      label: "សរុប",
                      value: amountText,
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade200),
                  Expanded(
                    child: _MiniInfoLight(
                      label: "Items",
                      value: "$itemsCount",
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChipLight extends StatelessWidget {
  final String status;
  const _StatusChipLight({required this.status});

  @override
  Widget build(BuildContext context) {
    final st = status.toLowerCase().trim();

    String text = "PENDING";
    IconData icon = Icons.hourglass_bottom;
    Color bg = const Color(0xFFFFF7E6);
    Color fg = const Color(0xFFB26A00);

    if (st.contains("paid") || st.contains("success")) {
      text = "PAID";
      icon = Icons.verified;
      bg = const Color(0xFFE9FFF6);
      fg = const Color(0xFF0B7A4B);
    } else if (st.contains("cancel") || st.contains("reject")) {
      text = "CANCELLED";
      icon = Icons.cancel;
      bg = const Color(0xFFFFEDED);
      fg = const Color(0xFFB42318);
    } else if (st.contains("deliver") || st.contains("ship")) {
      text = "DELIVERED";
      icon = Icons.local_shipping_outlined;
      bg = const Color(0xFFEAF3FF);
      fg = const Color(0xFF175CD3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: bg,
        border: Border.all(color: fg.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoLight extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfoLight({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
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
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ===================== LOADING / EMPTY / ERROR (LIGHT) ===================== */

class _LoadingListLight extends StatelessWidget {
  const _LoadingListLight();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 22),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        // ✅ FIX: remove fixed height -> no overflow
        // height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ important
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkelLineLight(h: 14, w: 220),
              SizedBox(height: 10),
              _SkelLineLight(h: 12, w: 160),
              SizedBox(height: 16),
              _SkelLineLight(h: 54, w: double.infinity),
              SizedBox(height: 14),
              _SkelLineLight(h: 12, w: 260),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkelLineLight extends StatelessWidget {
  final double h;
  final double w;
  const _SkelLineLight({required this.h, required this.w});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.grey.shade200,
      ),
    );
  }
}

class _CenterMessageLight extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CenterMessageLight({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBoxLight extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBoxLight({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onRetry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    "សាកម្តងទៀត",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
