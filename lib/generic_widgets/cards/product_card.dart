import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/generic_widgets/chips/rating_badge.dart';
import 'package:product_explorer/generic_widgets/images/app_network_image.dart';
import 'package:product_explorer/models/product_model.dart';
import 'package:product_explorer/utils/helper_functions.dart';

/// Grid tile on the Explore screen: square photo with the discount badge and
/// an out-of-stock scrim, then title, brand, rating and price.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(DataConst.kNormalBorderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-image-${product.id}',
                    child: AppNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _Badge(
                        label: HelperFunction.discountLabel(
                          product.discountPercentage,
                        ),
                        color: AppColors.orange,
                      ),
                    ),
                  if (!product.isInStock)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.red.withValues(alpha: 0.9),
                        alignment: Alignment.center,
                        child: Text('Out of stock', style: AppTextStyles.badge),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand.isNotEmpty
                          ? product.brand
                          : HelperFunction.titleCase(product.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardSubtitle,
                    ),
                    const Spacer(),
                    RatingBadge(rating: product.rating),
                    const SizedBox(height: 4),
                    _PriceRow(product: product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final ProductModel product;
  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            HelperFunction.price(product.discountedPrice),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.price,
          ),
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              HelperFunction.price(product.price),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.strikePrice,
            ),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DataConst.kLowBorderRadius),
      ),
      child: Text(label, style: AppTextStyles.badge),
    );
  }
}
