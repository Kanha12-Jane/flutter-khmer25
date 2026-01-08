import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_flutter_khmer25/components/home/home_list_product_horizontal_card.dart';
import 'package:project_flutter_khmer25/models/product_model.dart';
import 'package:project_flutter_khmer25/providers/product_provider.dart';

// Auth + Cart
import 'package:project_flutter_khmer25/providers/auth_provider.dart';
import 'package:project_flutter_khmer25/providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int qty = 1;
  bool _inited = false;
  bool _adding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    Future.microtask(() {
      context.read<ProductProvider>().fetchProductDetail(widget.productId);
    });
  }

  Future<void> _handleAddToCart(Product p) async {
    final auth = context.read<AuthProvider>();
    final cartProv = context.read<CartProvider>();

    if (!auth.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("សូម Login មុន ដើម្បីបន្ថែមចូលកន្ត្រក 🙏"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_adding) return;
    setState(() => _adding = true);

    try {
      final ok = await cartProv.addToCart(
        productId: p.id,
        qty: qty,
        accessToken: auth.access,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("បានបន្ថែម ${p.name} x$qty ចូលកន្ត្រក ✅"),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cartProv.error ?? "បន្ថែមមិនបាន ❌"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("បន្ថែមមិនបាន ❌\n$e"),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();
    final p = prov.detailProduct;

    if (prov.isLoadingDetail) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (prov.detailError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(prov.detailError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (p == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7FB),
        body: Center(child: Text("No product")),
      );
    }

    final hasDiscount = p.discountPercent > 0;
    final finalPrice = p.finalPrice;
    final oldPrice = p.price;
    final total = finalPrice * qty;
    final relatedProducts = p.relatedProducts.take(10).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        final isDesktop = w >= 1024;
        final isTablet = w >= 700 && w < 1024;

        final maxPageWidth = isDesktop ? 1120.0 : double.infinity;

        final sidePad = isDesktop ? 18.0 : 12.0;
        final topPad = isDesktop ? 16.0 : 12.0;

        final showBottomBar = !isDesktop;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7FB),
          appBar: AppBar(
            elevation: 0.2,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            foregroundColor: Colors.black,
            titleSpacing: 0,
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              _SoftIconButton(icon: Icons.share_outlined, onTap: () {}),
              const SizedBox(width: 8),
            ],
          ),
          bottomNavigationBar: showBottomBar
              ? _BottomBar(
                  qty: qty,
                  total: total,
                  adding: _adding,
                  inStock: p.isInStock,
                  onMinus: () => setState(() => qty = qty > 1 ? qty - 1 : 1),
                  onPlus: () => setState(() => qty = qty + 1),
                  onAdd: () => _handleAddToCart(p),
                )
              : null,
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxPageWidth),
              child: isDesktop
                  ? SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        sidePad,
                        topPad,
                        sidePad,
                        24,
                      ),
                      child: _DesktopBody(
                        p: p,
                        hasDiscount: hasDiscount,
                        finalPrice: finalPrice,
                        oldPrice: oldPrice,
                        qty: qty,
                        total: total,
                        adding: _adding,
                        relatedProducts: relatedProducts,
                        onMinus: () =>
                            setState(() => qty = qty > 1 ? qty - 1 : 1),
                        onPlus: () => setState(() => qty = qty + 1),
                        onAdd: () => _handleAddToCart(p),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.fromLTRB(sidePad, topPad, sidePad, 0),
                      child: _MobileBody(
                        p: p,
                        hasDiscount: hasDiscount,
                        finalPrice: finalPrice,
                        oldPrice: oldPrice,
                        relatedProducts: relatedProducts,
                        bottomSpace: isTablet ? 120 : 140,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ===================== THEME HELPERS =====================

const _kPrimaryBlue = Color(0xFF1D4ED8);
const _kPrimaryBlueDark = Color(0xFF1E40AF);

ButtonStyle _primaryButtonStyle({bool dense = false}) {
  return ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: _kPrimaryBlue,
    foregroundColor: Colors.white,
    disabledBackgroundColor: Colors.blueGrey.shade200,
    disabledForegroundColor: Colors.white.withOpacity(0.85),
    padding: EdgeInsets.symmetric(vertical: dense ? 13 : 16, horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ).copyWith(
    overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.10)),
  );
}

BoxDecoration _cardDeco() => BoxDecoration(
  borderRadius: BorderRadius.circular(18),
  color: Colors.white,
  border: Border.all(color: Colors.grey.shade200),
  boxShadow: [
    BoxShadow(
      blurRadius: 18,
      offset: const Offset(0, 8),
      color: Colors.black.withOpacity(0.03),
    ),
  ],
);

// ===================== DESKTOP BODY =====================

class _DesktopBody extends StatelessWidget {
  final Product p;
  final bool hasDiscount;
  final double finalPrice;
  final double oldPrice;
  final int qty;
  final double total;
  final bool adding;
  final List<Product> relatedProducts;

  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  const _DesktopBody({
    required this.p,
    required this.hasDiscount,
    required this.finalPrice,
    required this.oldPrice,
    required this.qty,
    required this.total,
    required this.adding,
    required this.relatedProducts,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImageCard(p: p, hasDiscount: hasDiscount),
              const SizedBox(height: 14),
              const _SectionTitle(title: "ផលិតផលពាក់ព័ន្ធ"),
              const SizedBox(height: 10),
              if (relatedProducts.isEmpty)
                const _EmptyCard(
                  text: "មិនទាន់មានផលិតផលពាក់ព័ន្ធក្នុងប្រភេទដូចគ្នា។",
                )
              else
                ProductHorizontalList(products: relatedProducts),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _TitlePriceCard(
                p: p,
                hasDiscount: hasDiscount,
                finalPrice: finalPrice,
                oldPrice: oldPrice,
              ),
              const SizedBox(height: 14),
              const _SectionTitle(title: "ពិពណ៌នា"),
              const SizedBox(height: 8),
              _DescriptionCard(description: p.description),
              const SizedBox(height: 14),
              _DesktopAddToCartCard(
                qty: qty,
                total: total,
                adding: adding,
                inStock: p.isInStock,
                onMinus: onMinus,
                onPlus: onPlus,
                onAdd: onAdd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== MOBILE BODY =====================

class _MobileBody extends StatelessWidget {
  final Product p;
  final bool hasDiscount;
  final double finalPrice;
  final double oldPrice;
  final List<Product> relatedProducts;
  final double bottomSpace;

  const _MobileBody({
    required this.p,
    required this.hasDiscount,
    required this.finalPrice,
    required this.oldPrice,
    required this.relatedProducts,
    required this.bottomSpace,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomSpace),
      children: [
        _ProductImageCard(p: p, hasDiscount: hasDiscount),
        const SizedBox(height: 12),
        _TitlePriceCard(
          p: p,
          hasDiscount: hasDiscount,
          finalPrice: finalPrice,
          oldPrice: oldPrice,
        ),
        const SizedBox(height: 14),
        const _SectionTitle(title: "ពិពណ៌នា"),
        const SizedBox(height: 8),
        _DescriptionCard(description: p.description),
        const SizedBox(height: 18),
        const _SectionTitle(title: "ផលិតផលពាក់ព័ន្ធ"),
        const SizedBox(height: 10),
        if (relatedProducts.isEmpty)
          const _EmptyCard(text: "មិនទាន់មានផលិតផលពាក់ព័ន្ធក្នុងប្រភេទដូចគ្នា។")
        else
          ProductHorizontalList(products: relatedProducts),
      ],
    );
  }
}

// ===================== UI CARDS =====================

class _ProductImageCard extends StatelessWidget {
  final Product p;
  final bool hasDiscount;

  const _ProductImageCard({required this.p, required this.hasDiscount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'product_${p.id}',
              child: Image.network(
                p.image ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
            if (hasDiscount)
              Positioned(
                top: 12,
                left: 12,
                child: _DiscountPill(percent: p.discountPercent),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: _StockPill(inStock: p.isInStock),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitlePriceCard extends StatelessWidget {
  final Product p;
  final bool hasDiscount;
  final double finalPrice;
  final double oldPrice;

  const _TitlePriceCard({
    required this.p,
    required this.hasDiscount,
    required this.finalPrice,
    required this.oldPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (p.unit != null && p.unit!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Text(
                    p.unit!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _kPrimaryBlueDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${_fmt(finalPrice)}៛",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kPrimaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              if (hasDiscount)
                Text(
                  "${_fmt(oldPrice)}៛",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _InfoTile(
                  icon: Icons.local_shipping_outlined,
                  title: "ដឹកជញ្ជូន",
                  subtitle: "ក្នុងថ្ងៃ / 1–2ថ្ងៃ",
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.verified_outlined,
                  title: "ទំនុកចិត្ត",
                  subtitle: "ផលិតផលគុណភាព",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String? description;
  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        (description?.isNotEmpty == true) ? description! : "មិនទាន់មានពិពណ៌នា។",
        style: TextStyle(
          color: Colors.grey.shade800,
          height: 1.55,
          fontSize: 14.5,
        ),
      ),
    );
  }
}

class _DesktopAddToCartCard extends StatelessWidget {
  final int qty;
  final double total;
  final bool adding;
  final bool inStock;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  const _DesktopAddToCartCard({
    required this.qty,
    required this.total,
    required this.adding,
    required this.inStock,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(
        children: [
          _QtySelector(qty: qty, onMinus: onMinus, onPlus: onPlus),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              style: _primaryButtonStyle(),
              onPressed: (adding || !inStock) ? null : onAdd,
              child: adding
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      inStock
                          ? "បន្ថែមចូលកន្ត្រក • ${_fmt(total)}៛"
                          : "អស់ស្តុក",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== BOTTOM BAR =====================

class _BottomBar extends StatelessWidget {
  final int qty;
  final double total;
  final bool adding;
  final bool inStock;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  const _BottomBar({
    required this.qty,
    required this.total,
    required this.adding,
    required this.inStock,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            _QtySelector(qty: qty, onMinus: onMinus, onPlus: onPlus),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: _primaryButtonStyle(dense: true),
                onPressed: (adding || !inStock) ? null : onAdd,
                child: adding
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        inStock
                            ? "បន្ថែមចូលកន្ត្រក • ${_fmt(total)}៛"
                            : "អស់ស្តុក",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
    );
  }
}

// ===================== SOLID INFO TILE (UPDATED) =====================

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ solid backgrounds (delivery + trust)
    final solidBg = _kPrimaryBlue;
    final solidBg2 = _kPrimaryBlueDark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [solidBg, solidBg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: _kPrimaryBlue.withOpacity(0.18),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.92),
                    fontWeight: FontWeight.w600,
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

// ===================== OTHER SMALL WIDGETS =====================

class _DiscountPill extends StatelessWidget {
  final int percent;
  const _DiscountPill({required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "-$percent%",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  final bool inStock;
  const _StockPill({required this.inStock});

  @override
  Widget build(BuildContext context) {
    final bg = inStock ? const Color(0xFFE9FFF6) : const Color(0xFFFFEDED);
    final fg = inStock ? const Color(0xFF0B7A4B) : const Color(0xFFB42318);
    final text = inStock ? "IN STOCK" : "OUT";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _QtySelector extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _QtySelector({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        color: const Color(0xFFF8FAFF),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniBlueButton(icon: Icons.remove, onTap: onMinus),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28),
            child: Text(
              "$qty",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          _MiniBlueButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _MiniBlueButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniBlueButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFEFF6FF),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Icon(icon, size: 20, color: _kPrimaryBlueDark),
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SoftIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Icon(icon, color: _kPrimaryBlueDark),
        ),
      ),
    );
  }
}

String _fmt(double v) => v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
