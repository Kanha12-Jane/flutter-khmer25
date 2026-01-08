import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_flutter_khmer25/screens/product_detail_screen.dart';

import '../core/api_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/category_product_provider.dart';

class CategoryProductScreen extends StatefulWidget {
  final CategoryModel initialParent;
  final String? accessToken;

  const CategoryProductScreen({
    super.key,
    required this.initialParent,
    this.accessToken,
  });

  @override
  State<CategoryProductScreen> createState() => _CategoryProductScreenState();
}

class _CategoryProductScreenState extends State<CategoryProductScreen> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    Future.microtask(() {
      context.read<CategoryProductProvider>().initWithInitial(
        widget.initialParent,
        accessToken: widget.accessToken,
      );
    });
  }

  Future<void> _onRefresh() async {
    final p = context.read<CategoryProductProvider>();
    await p.fetchCategories(accessToken: widget.accessToken);
    await p.fetchProducts(accessToken: widget.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CategoryProductProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;

              final bool isDesktop = w >= 1200; // PC
              final bool isPhone = w < 800; // phone
              final bool isTablet = !isDesktop && !isPhone;

              final int crossAxisCount = isDesktop ? 6 : (isTablet ? 4 : 3);
              final double sidePad = isDesktop ? 28 : 12;

              // ✅ image height
              final double imageH = isDesktop ? 170 : (isTablet ? 160 : 150);

              // ✅ grid sizing
              final double childAspectRatio = isDesktop
                  ? 0.74
                  : (isTablet ? 0.68 : 0.64);

              // ✅ BACK TO OLD HEIGHT (shorter card)
              // Old logic: imageH + 140
              final double? mainAxisExtent = isPhone ? (imageH + 140) : null;

              // ✅ heights for category tiles
              final double parentTileHeight = 120;
              final double subTileHeight = 110;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // =================== HEADER ===================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(sidePad, 14, sidePad, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Category Products',
                              style: TextStyle(
                                fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (p.loadingCats || p.loadingProducts)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // =================== PARENTS ===================
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: parentTileHeight,
                      child: p.loadingCats
                          ? const Center(child: CircularProgressIndicator())
                          : p.parents.isEmpty
                          ? _stateBox(
                              const Text('No categories'),
                              height: parentTileHeight,
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: sidePad,
                              ),
                              itemCount: p.parents.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final cat = p.parents[i];
                                final selected = cat.id == p.selectedParentId;

                                return _CategoryTile(
                                  name: cat.name,
                                  imageUrl: cat.image,
                                  selected: selected,
                                  onTap: () => p.selectParent(
                                    cat,
                                    accessToken: widget.accessToken,
                                  ),
                                  size: isDesktop ? 76 : 66,
                                  textWidth: isDesktop ? 92 : 78,
                                  tileHeight: parentTileHeight,
                                );
                              },
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // =================== SUBS ===================
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: subTileHeight,
                      child: p.loadingCats
                          ? const SizedBox.shrink()
                          : p.subs.isEmpty
                          ? _stateBox(
                              Text(
                                'No subcategories',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              height: subTileHeight,
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: sidePad,
                              ),
                              itemCount: p.subs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final s = p.subs[i];
                                final selected = s.id == p.selectedSubId;

                                return _CategoryTile(
                                  name: s.name,
                                  imageUrl: s.image,
                                  selected: selected,
                                  onTap: () => p.selectSub(
                                    s,
                                    accessToken: widget.accessToken,
                                  ),
                                  size: isDesktop ? 70 : 62,
                                  textWidth: isDesktop ? 96 : 78,
                                  tileHeight: subTileHeight,
                                );
                              },
                            ),
                    ),
                  ),

                  // =================== ERROR ===================
                  if (p.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(sidePad, 10, sidePad, 0),
                        child: _ErrorBox(message: p.error!),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 6)),

                  // =================== PRODUCTS GRID ===================
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(sidePad, 10, sidePad, 18),
                    sliver: p.loadingProducts
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : p.products.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(child: Text('No products')),
                            ),
                          )
                        : SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _ProductCard(
                                product: p.products[i],
                                imageHeight: imageH,
                                isDesktop: isDesktop,
                                isPhone: isPhone,
                              ),
                              childCount: p.products.length,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                  mainAxisExtent:
                                      mainAxisExtent, // ✅ old height
                                ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _stateBox(Widget child, {required double height}) {
    return SizedBox(
      height: height,
      child: Center(child: child),
    );
  }
}

// ==================== ERROR BOX ====================
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC7C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CATEGORY TILE (FIX OVERFLOW) ====================
class _CategoryTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  final double size;
  final double textWidth;
  final double tileHeight;

  const _CategoryTile({
    required this.name,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
    required this.size,
    required this.textWidth,
    required this.tileHeight,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    const double padV = 8;
    const double padH = 10;
    const double gap = 6;

    return SizedBox(
      height: tileHeight,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color: selected ? primary.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? primary.withOpacity(0.70)
                  : Colors.grey.shade200,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              const double fontSize = 12;
              const double lineH = fontSize * 1.15;
              final double titleH = lineH * 2;

              final double availForImage =
                  c.maxHeight - (padV * 2) - gap - titleH;

              final double img = math.max(44, math.min(size, availForImage));

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: img,
                    height: img,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _NetImage(imageUrl),
                    ),
                  ),
                  const SizedBox(height: gap),
                  SizedBox(
                    width: textWidth,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.15,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: selected ? primary : Colors.black87,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==================== NET IMAGE ====================
class _NetImage extends StatelessWidget {
  final String? url;
  const _NetImage(this.url);

  @override
  Widget build(BuildContext context) {
    final full = ApiConfig.toUrl(url);

    if (full.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.image_not_supported_outlined)),
      );
    }

    return Image.network(
      full,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}

// ==================== PRODUCT CARD (OLD HEIGHT + NO RIGHT OVERFLOW) ====================
class _ProductCard extends StatelessWidget {
  final Product product;
  final double imageHeight;
  final bool isDesktop;
  final bool isPhone;

  const _ProductCard({
    required this.product,
    required this.imageHeight,
    required this.isDesktop,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    final primary = Theme.of(context).colorScheme.primary;
    final pad = isPhone ? 10.0 : 12.0;

    // ✅ fixed title height to prevent overflow while keeping card short
    final double titleBoxH = isDesktop ? 36 : 34;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: p.id),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: imageHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: _NetImage(p.image),
                      ),
                    ),
                    if (p.discountPercent > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _DiscountBadge(p.discountPercent),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, pad),
                  child: Column(
                    children: [
                      // ✅ title fixed height (2 lines safe)
                      SizedBox(
                        height: titleBoxH,
                        child: Center(
                          child: Text(
                            p.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 13,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ✅ Wrap fixes RIGHT OVERFLOW (7.1) on small screens
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            '${_fmt(p.finalPrice)}៛',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w900,
                              fontSize: isDesktop ? 15 : 14,
                            ),
                          ),
                          if (p.discountPercent > 0)
                            Text(
                              '${_fmt(p.price)}៛',
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ✅ unit tag with background (beautiful) + safe width
                      if (p.unit != null && p.unit!.isNotEmpty)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary.withOpacity(0.18),
                                  primary.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: primary.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.straighten,
                                  size: 14,
                                  color: primary.withOpacity(0.85),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '/ ${p.unit}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: primary.withOpacity(0.95),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

class _DiscountBadge extends StatelessWidget {
  final int percent;
  const _DiscountBadge(this.percent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 8),
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

String _fmt(double v) => v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
