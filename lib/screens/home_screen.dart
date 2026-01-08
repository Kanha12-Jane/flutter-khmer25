import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_flutter_khmer25/models/category_model.dart';
import 'package:project_flutter_khmer25/models/product_model.dart';

import 'package:project_flutter_khmer25/components/home/home_banner.dart';
import 'package:project_flutter_khmer25/components/home/home_category_navbar.dart';
import 'package:project_flutter_khmer25/components/home/home_list_product_horizontal_card.dart';

import 'package:project_flutter_khmer25/providers/product_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenNew;
  final VoidCallback onOpenDiscount;
  final void Function(CategoryModel cat) onOpenCategory;

  const HomeScreen({
    super.key,
    required this.onOpenNew,
    required this.onOpenDiscount,
    required this.onOpenCategory,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    // ✅ load first page for both sections
    Future.microtask(() async {
      final prov = context.read<ProductProvider>();
      await prov.initFirstPage(ProductFilterType.newProducts);
      await prov.initFirstPage(ProductFilterType.discountProducts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    final loadingNew = productProvider.isLoading(ProductFilterType.newProducts);
    final loadingDiscount = productProvider.isLoading(
      ProductFilterType.discountProducts,
    );

    final newItems = productProvider.newProducts;
    final discountItems = productProvider.discountProducts;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          // ✅ content width for sections (not banner)
          final contentWidth = w < 600
              ? w * 0.95
              : (w < 1100 ? w * 0.90 : 1100.0);

          // ✅ banner padding (keep clean)
          final bannerPad = w < 600 ? 10.0 : (w < 1100 ? 16.0 : 24.0);

          // ✅ banner ratio: phone tall a bit, desktop wide
          final bannerRatio = w < 600 ? (16 / 9) : (24 / 9); // 16:9 , 24:9

          // ✅ control banner height so PC not too big
          final minBannerH = w < 600 ? 170.0 : 220.0;
          final maxBannerH = w < 600 ? 220.0 : 320.0;

          // height computed from ratio but clamped
          double desiredH = (w - (bannerPad * 2)) / bannerRatio;
          desiredH = desiredH.clamp(minBannerH, maxBannerH);

          return RefreshIndicator(
            onRefresh: () async {
              // ✅ refresh both sections
              await context.read<ProductProvider>().refresh(
                ProductFilterType.newProducts,
              );
              await context.read<ProductProvider>().refresh(
                ProductFilterType.discountProducts,
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // =========================
                  // ✅ Banner FULL + CLEAN + BEAUTIFUL
                  // =========================
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: bannerPad),
                    child: SizedBox(
                      width: double.infinity,
                      height: desiredH, // ⭐ not too big on PC
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: const _BannerCover(child: HomeBanner()),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // Sections (center width)
                  // =========================
                  Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionCard(
                              context: context,
                              title: 'ប្រភេទ',
                              child: HomeCategoryNavbar(
                                onOpenCategory: widget.onOpenCategory,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _sectionCard(
                              context: context,
                              title: 'ផលិតផលថ្មីៗ',
                              rightText: 'មើលទាំងអស់',
                              onRightTap: widget.onOpenNew,
                              child: _productBlock(
                                loading: loadingNew,
                                products: newItems,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _sectionCard(
                              context: context,
                              title: 'ផលិតផលបញ្ចុះតម្លៃ (%)',
                              rightText: 'មើលទាំងអស់',
                              onRightTap: widget.onOpenDiscount,
                              child: _productBlock(
                                loading: loadingDiscount,
                                products: discountItems,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ======================================================
  // Helpers
  // ======================================================

  Widget _productBlock({
    required bool loading,
    required List<Product> products,
  }) {
    if (loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (products.isEmpty) {
      return const SizedBox(
        height: 90,
        child: Center(child: Text('No products')),
      );
    }

    // ✅ Your horizontal list widget expects List<Product>
    return ProductHorizontalList(products: products);
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    String? rightText,
    VoidCallback? onRightTap,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            context: context,
            title: title,
            rightText: rightText,
            onRightTap: onRightTap,
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required BuildContext context,
    required String title,
    String? rightText,
    VoidCallback? onRightTap,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (rightText != null)
          TextButton(onPressed: onRightTap, child: Text(rightText)),
      ],
    );
  }
}

/// ✅ If HomeBanner is image/slider, this keeps it "cover" without overflow.
class _BannerCover extends StatelessWidget {
  final Widget child;
  const _BannerCover({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(width: MediaQuery.of(context).size.width, child: child),
      ),
    );
  }
}
