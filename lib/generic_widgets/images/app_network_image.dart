import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';

/// Remote image with placeholder, error and fade-in states. Every image in
/// this app is a DummyJSON cdn url, so the rounding is built in rather than
/// wrapped at each usage.
///
/// Deliberately `Image.network` and not `cached_network_image`: that package
/// pulls in flutter_cache_manager -> path_provider + sqflite, and
/// path_provider_foundation 2.6.0 ships no podspec - its `objective_c`
/// framework has to come from Dart's native-assets build hooks, which did not
/// land in the app bundle on this toolchain. Flutter's built-in ImageCache
/// (1000 images / 100MB) covers scrolling back up a grid, which is all this
/// app needs the cache for.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? height, width;
  final double radius;
  final Alignment alignment;
  final Color backgroundColor;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.radius = 0,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.backgroundColor = AppColors.imagePlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url.isEmpty
          ? _fallback()
          : Image.network(
              url,
              height: height,
              width: width,
              fit: fit,
              alignment: alignment,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _placeholder(),
              errorBuilder: (_, _, _) => _fallback(),
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
            ),
    );
  }

  Widget _placeholder() =>
      Container(height: height, width: width, color: backgroundColor);

  Widget _fallback() => Container(
    height: height,
    width: width,
    color: backgroundColor,
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.greyText),
  );
}
