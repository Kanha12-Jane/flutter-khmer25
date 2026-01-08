import 'package:flutter/material.dart';
import 'package:project_flutter_khmer25/models/product_model.dart';
import 'package:project_flutter_khmer25/screens/product_detail_screen.dart';

class ProductHorizontalList extends StatelessWidget {
  final List<Product> products;
  const ProductHorizontalList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _ProductCard(product: products[i]),
      ),
    );
  }
}

// -------------------- CARD --------------------
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;

    return SizedBox(
      width: 160,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // ✅ NEW: open detail by ID
              builder: (_) => ProductDetailScreen(productId: p.id),
            ),
          );
        },
        child: Card(
          color: Colors.white,
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
                    Positioned.fill(
                      child: Hero(
                        tag: 'product_${p.id}',
                        child: _NetImage(p.image),
                      ),
                    ),
                    if (p.discountPercent > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _DiscountBadge(p.discountPercent),
                      ),
                  ],
                ),
              ),

              // CONTENT
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 8),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_fmt(p.finalPrice)}៛',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
      loadingBuilder: (c, child, p) => p == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

// -------------------- FORMATTER --------------------
String _fmt(double v) => v < 1 ? v.toStringAsFixed(2) : v.toStringAsFixed(0);
