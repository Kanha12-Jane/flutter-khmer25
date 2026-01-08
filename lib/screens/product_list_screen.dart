import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_flutter_khmer25/models/product_model.dart';
import 'package:project_flutter_khmer25/providers/product_provider.dart';
import 'package:project_flutter_khmer25/screens/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final ProductFilterType type;
  final VoidCallback? onBack;
  const ProductListScreen({super.key, required this.type, this.onBack});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scrollCtrl = ScrollController();
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final max = _scrollCtrl.position.maxScrollExtent;
    final cur = _scrollCtrl.position.pixels;

    // ✅ near bottom -> load more
    if (cur >= max - 300) {
      context.read<ProductProvider>().loadMore(widget.type);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    Future.microtask(() {
      context.read<ProductProvider>().initFirstPage(widget.type);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();

    final title = widget.type == ProductFilterType.newProducts
        ? 'ផលិតផលថ្មីៗ'
        : 'ផលិតផលបញ្ចុះតម្លៃ';

    final items = widget.type == ProductFilterType.newProducts
        ? prov.newProducts
        : prov.discountProducts;

    final isLoading = prov.isLoading(widget.type);
    final isLoadingMore = prov.isLoadingMore(widget.type);
    final err = prov.error(widget.type);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) return widget.onBack!();
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : err != null
          ? Center(child: Text(err))
          : RefreshIndicator(
              onRefresh: () =>
                  context.read<ProductProvider>().refresh(widget.type),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;

                  // ✅ Requirements: Phone=3, PC=6
                  final int crossAxisCount = w >= 1000 ? 6 : 3;

                  const double spacing = 12;
                  const double pad = 12;

                  final double tileW =
                      (w - (pad * 2) - (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;

                  const double infoH = 92;
                  final double mainAxisExtent = tileW + infoH;

                  // ✅ add 1 extra tile for bottom loader
                  final int extra = isLoadingMore ? 1 : 0;
                  final int count = items.length + extra;

                  if (items.isEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 120),
                        Center(child: Text('No products')),
                      ],
                    );
                  }

                  return GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(pad),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: mainAxisExtent,
                    ),
                    itemCount: count,
                    itemBuilder: (_, i) {
                      if (i >= items.length) {
                        return const _BottomLoaderTile();
                      }
                      return _ProductCard(product: items[i]);
                    },
                  );
                },
              ),
            ),
    );
  }
}

// -------------------- PRODUCT CARD --------------------
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = product;
    final hasDiscount = p.discountPercent > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(context),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
            border: Border.all(color: const Color(0xFFEDEFF5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _NetImage(p.image)),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.04),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _DiscountBadge(p.discountPercent),
                      ),
                    if (p.isNew == true)
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: _Chip(text: 'NEW'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${_fmt(p.finalPrice)}៛',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        if (hasDiscount)
                          Text(
                            '${_fmt(p.price)}៛',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (p.unit != null && p.unit!.isNotEmpty)
                          Text(
                            '/ ${p.unit}',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- BOTTOM LOADER TILE --------------------
class _BottomLoaderTile extends StatelessWidget {
  const _BottomLoaderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEFF5), width: 1),
      ),
      child: const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      ),
    );
  }
}

// -------------------- BADGE --------------------
class _DiscountBadge extends StatelessWidget {
  final int percent;
  const _DiscountBadge(this.percent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// -------------------- IMAGE --------------------
class _NetImage extends StatelessWidget {
  final String? url;
  const _NetImage(this.url);

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

// -------------------- FORMAT --------------------
String _fmt(double v) => v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
