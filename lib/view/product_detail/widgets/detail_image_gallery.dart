import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/generic_widgets/images/app_network_image.dart';

/// Swipeable photo gallery with a dot indicator. The first page carries the
/// Hero tag the grid card used, so the thumbnail flies into place and then
/// the full-size image fades in over it.
class DetailImageGallery extends StatefulWidget {
  final int productId;
  final List<String> images;

  const DetailImageGallery({
    super.key,
    required this.productId,
    required this.images,
  });

  @override
  State<DetailImageGallery> createState() => _DetailImageGalleryState();
}

class _DetailImageGalleryState extends State<DetailImageGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return ColoredBox(
      color: AppColors.imagePlaceholder,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            Hero(
              tag: 'product-image-${widget.productId}',
              child: const AppNetworkImage(imageUrl: null),
            )
          else
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, index) {
                final image = AppNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                );
                return index == 0
                    ? Hero(
                        tag: 'product-image-${widget.productId}',
                        child: image,
                      )
                    : image;
              },
            ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.primary
                            : AppColors.greyText.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
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
