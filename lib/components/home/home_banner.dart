import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project_flutter_khmer25/providers/banner_provider.dart';
import 'package:project_flutter_khmer25/models/banner_model.dart';

/// ✅ Responsive + Professional Banner Slider (Phone + PC/Web)
class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _bannerIndex = 0;
  final PageController _controller = PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _bannerHeight(double width) {
    // Phone -> Medium -> PC
    if (width < 420) return 170;
    if (width < 900) return 210;
    return 280;
  }

  double _maxContentWidth(double width) {
    // Centered layout for PC/Web
    if (width >= 1200) return 1100;
    if (width >= 900) return 900;
    return width; // phone/tablet use full width
  }

  @override
  Widget build(BuildContext context) {
    final bannerProv = context.watch<BannerProvider>();
    final List<BannerModel> banners = bannerProv.banners;

    if (banners.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No banners')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = _bannerHeight(width);
        final maxW = _maxContentWidth(width);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Card container with shadow (looks pro on PC)
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: banners.length,
                      onPageChanged: (index) =>
                          setState(() => _bannerIndex = index),
                      itemBuilder: (context, index) {
                        final banner = banners[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _BannerItem(imageUrl: banner.imageUrl),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Indicator
                _DotsIndicator(
                  count: banners.length,
                  activeIndex: _bannerIndex,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BannerItem extends StatelessWidget {
  final String imageUrl;

  const _BannerItem({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ✅ Image (with loading + error)
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    value: progress.expectedTotalBytes == null
                        ? null
                        : progress.cumulativeBytesLoaded /
                              (progress.expectedTotalBytes ?? 1),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, size: 34),
            );
          },
        ),

        // ✅ Gradient overlay (more professional)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),

        // ✅ subtle border
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;
  final Color activeColor;

  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
