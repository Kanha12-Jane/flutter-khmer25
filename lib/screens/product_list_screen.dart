import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_flutter_khmer25/models/product_model.dart';
import 'package:project_flutter_khmer25/providers/product_provider.dart';

// ✅ CHANGE THIS to your real detail screen file/class
import 'package:project_flutter_khmer25/screens/product_detail_screen.dart';

enum ProductFilterType { newProducts, discountProducts }

class ProductListScreen extends StatelessWidget {
  final ProductFilterType type;
  final VoidCallback? onBack;
  const ProductListScreen({super.key, required this.type, this.onBack});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProductProvider>();

    final title = type == ProductFilterType.newProducts
        ? 'ផលិតផលថ្មីៗ'
        : 'ផលិតផលបញ្ចុះតម្លៃ';

    final items = type == ProductFilterType.newProducts
        ? prov.newProducts
        : prov.discountProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) return onBack!();
            Navigator.pop(context);
          },
        ),
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
          ? Center(child: Text(prov.error!))
          : items.isEmpty
          ? const Center(child: Text('No products'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 275,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _ProductCard(product: items[i]),
            ),
    );
  }
}

// -------------------- CARD --------------------
class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  void _openDetail(BuildContext context) {
    // ✅ push to detail page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
        // or if your detail takes Product:
        // builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = product;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(context),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // IMAGE
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(child: _NetImage(p.image)),
                    if (p.discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _DiscountBadge(p.discountPercent),
                      ),
                  ],
                ),
              ),

              // INFO
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_fmt(p.finalPrice)}៛',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (p.discountPercent > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_fmt(p.price)}៛',
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (p.unit != null && p.unit!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '/ ${p.unit}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

// -------------------- BADGE --------------------
class _DiscountBadge extends StatelessWidget {
  final int percent;
  const _DiscountBadge(this.percent);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '-$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
      return const Center(child: Icon(Icons.image_not_supported_outlined));
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

// -------------------- FORMAT --------------------
String _fmt(double v) => v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
