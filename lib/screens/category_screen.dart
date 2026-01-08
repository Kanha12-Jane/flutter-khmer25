import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../core/api_config.dart';

class CategoryScreen extends StatelessWidget {
  final void Function(CategoryModel cat) onOpenCategory;
  const CategoryScreen({super.key, required this.onOpenCategory});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CategoryProvider>();

    if (prov.isLoading) return const _CategoryLoadingGrid();
    if (prov.error != null) return _ErrorState(message: prov.error!);
    if (prov.categories.isEmpty) return const _EmptyState();

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // ✅ Responsive crossAxisCount for phone/tablet/desktop
        int crossAxisCount;
        if (w < 480) {
          crossAxisCount = 2;
        } else if (w < 760) {
          crossAxisCount = 3;
        } else if (w < 1100) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 6;
        }

        // ✅ Adjust spacing & card ratio to look pro on desktop too
        final spacing = w < 760 ? 12.0 : 16.0;
        final childAspectRatio = w < 480 ? 0.82 : (w < 760 ? 0.86 : 0.92);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.builder(
              padding: EdgeInsets.all(spacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: prov.categories.length,
              itemBuilder: (_, i) {
                final cat = prov.categories[i];
                return _CategoryCard(
                  cat: cat,
                  onTap: () => onOpenCategory(cat),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// =======================
// UI: Category Card (Pro + Hover)
// =======================
class _CategoryCard extends StatefulWidget {
  final CategoryModel cat;
  final VoidCallback onTap;

  const _CategoryCard({required this.cat, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(18);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _hover ? 1.015 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _hover
                  ? [Colors.white, Colors.grey.shade50]
                  : [Colors.white, Colors.white],
            ),
            border: Border.all(
              color: _hover
                  ? Colors.black.withOpacity(.08)
                  : Colors.black.withOpacity(.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? .10 : .06),
                blurRadius: _hover ? 18 : 14,
                offset: Offset(0, _hover ? 10 : 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ✅ image
                            Image.network(
                              ApiConfig.toUrl(widget.cat.image),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const _ImageSkeleton();
                              },
                            ),

                            // ✅ subtle gradient overlay for pro look
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(.08),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ name (only)
                    Text(
                      widget.cat.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        height: 1.15,
                      ),
                    ),

                    // ✅ removed "View" here
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =======================
// Loading / Empty / Error
// =======================
class _CategoryLoadingGrid extends StatelessWidget {
  const _CategoryLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        int crossAxisCount;
        if (w < 480) {
          crossAxisCount = 2;
        } else if (w < 760) {
          crossAxisCount = 3;
        } else if (w < 1100) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 6;
        }

        final spacing = w < 760 ? 12.0 : 16.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.builder(
              padding: EdgeInsets.all(spacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: w < 480 ? 0.82 : 0.9,
              ),
              itemCount: 12,
              itemBuilder: (_, __) => const _CardSkeleton(),
            ),
          ),
        );
      },
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: Colors.black.withOpacity(.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Expanded(child: _ImageSkeleton()),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: Colors.grey.shade500),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 56,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                "No categories",
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Please add categories in admin or check your API.",
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 10),
                Text(
                  "Something went wrong",
                  style: t.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
