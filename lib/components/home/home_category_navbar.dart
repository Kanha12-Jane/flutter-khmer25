import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_flutter_khmer25/models/category_model.dart';
import 'package:project_flutter_khmer25/providers/category_provider.dart';

class HomeCategoryNavbar extends StatelessWidget {
  final void Function(CategoryModel cat) onOpenCategory;

  const HomeCategoryNavbar({super.key, required this.onOpenCategory});

  double _maxContentWidth(double width) {
    if (width >= 1400) return 1200;
    if (width >= 1100) return 980;
    if (width >= 900) return 860;
    return width;
  }

  bool _useGrid(double width) => width >= 900;

  double _tileSize(double width) {
    if (width >= 1400) return 78;
    if (width >= 1200) return 74;
    if (width >= 1000) return 70;
    if (width >= 900) return 66;
    return 64;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    if (provider.isLoading) return _stateBox(const CircularProgressIndicator());
    if (provider.error != null) return _stateBox(Text(provider.error!));
    if (provider.categories.isEmpty) {
      return _stateBox(const Text('No categories'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final maxW = _maxContentWidth(w);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _useGrid(w)
                  ? _CategoryWrapGrid(
                      categories: provider.categories,
                      onOpenCategory: onOpenCategory,
                      tileSize: _tileSize(w),
                    )
                  : _CategoryHorizontal(
                      categories: provider.categories,
                      onOpenCategory: onOpenCategory,
                      tileSize: 64,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _stateBox(Widget child) =>
      SizedBox(height: 120, child: Center(child: child));
}

/// =======================
/// Phone layout: Horizontal scroll
/// =======================
class _CategoryHorizontal extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel cat) onOpenCategory;
  final double tileSize;

  const _CategoryHorizontal({
    required this.categories,
    required this.onOpenCategory,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // ✅ a bit more to allow bottom margin
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final cat = categories[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8), // ✅ margin bottom
            child: _CategoryTile(
              cat: cat,
              size: tileSize,
              onTap: () => onOpenCategory(cat),
              centerText: true,
              compact: true,
            ),
          );
        },
      ),
    );
  }
}

/// =======================
/// PC/Web layout: Wrap Grid (auto height)
/// =======================
class _CategoryWrapGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel cat) onOpenCategory;
  final double tileSize;

  const _CategoryWrapGrid({
    required this.categories,
    required this.onOpenCategory,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final available = c.maxWidth;
        final itemW = tileSize + 22;
        var cols = (available / itemW).floor();
        cols = cols.clamp(4, 8);

        final spacing = 14.0;

        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final cat in categories)
                SizedBox(
                  width: (available - (spacing * (cols - 1))) / cols,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                    ), // ✅ margin bottom
                    child: _CategoryTile(
                      cat: cat,
                      size: tileSize,
                      onTap: () => onOpenCategory(cat),
                      centerText: true,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// =======================
/// Reusable tile (hover + ripple + shadow)
/// =======================
class _CategoryTile extends StatefulWidget {
  final CategoryModel cat;
  final double size;
  final VoidCallback onTap;
  final bool centerText;
  final bool compact;

  const _CategoryTile({
    required this.cat,
    required this.size,
    required this.onTap,
    this.centerText = false,
    this.compact = false,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hover = false;

  bool _isMouse(PointerEnterEvent e) => e.kind == PointerDeviceKind.mouse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final radius = BorderRadius.circular(18);

    return MouseRegion(
      onEnter: (e) {
        if (_isMouse(e)) setState(() => _hover = true);
      },
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(widget.compact ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white, // ✅ white background
              borderRadius: radius,
              border: Border.all(
                color: _hover
                    ? primary.withOpacity(0.35)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hover ? 0.10 : 0.06),
                  blurRadius: _hover ? 16 : 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: primary.withOpacity(0.06),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _CategoryImage(widget.cat.image),
                  ),
                ),
                SizedBox(height: widget.compact ? 6 : 8),
                Text(
                  widget.cat.name,
                  textAlign: widget.centerText
                      ? TextAlign.center
                      : TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
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

class _CategoryImage extends StatelessWidget {
  final String? url;
  const _CategoryImage(this.url);

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                value: progress.expectedTotalBytes == null
                    ? null
                    : progress.cumulativeBytesLoaded /
                          (progress.expectedTotalBytes ?? 1),
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) =>
          Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
    );
  }
}
