import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/generic_widgets/chips/rating_badge.dart';
import 'package:product_explorer/models/product_detail_model.dart';
import 'package:product_explorer/utils/helper_functions.dart';
import 'package:product_explorer/view/product_detail/widgets/review_tile.dart';

/// Everything under the gallery: name, price, stock, description, specs and
/// reviews. Pure presentation - it receives a loaded model and nothing else.
class DetailInfoSection extends StatelessWidget {
  final ProductDetailModel detail;

  const DetailInfoSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final product = detail.product;
    const side = DataConst.kScreenHorizontalPadding * 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(side, 16, side, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  product.brand.isNotEmpty
                      ? product.brand
                      : HelperFunction.titleCase(product.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              RatingBadge(
                rating: product.rating,
                reviewCount: detail.reviews.length,
                size: 13,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(product.title, style: AppTextStyles.detailTitle),
          const SizedBox(height: 10),
          _PriceBlock(detail: detail),
          const SizedBox(height: 8),
          _StockLine(detail: detail),
          if (product.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in product.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const ShapeDecoration(
                      color: AppColors.primaryLight,
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('Description', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 6),
          Text(product.description, style: AppTextStyles.body),
          const SizedBox(height: 20),
          Text('Details', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 6),
          _SpecRow(label: 'Category', value: HelperFunction.titleCase(product.category)),
          if (detail.sku.isNotEmpty) _SpecRow(label: 'SKU', value: detail.sku),
          if (detail.weight > 0)
            _SpecRow(label: 'Weight', value: '${detail.weight.round()} g'),
          if (detail.dimensions != null)
            _SpecRow(label: 'Dimensions', value: detail.dimensions!.label),
          if (detail.minimumOrderQuantity > 1)
            _SpecRow(
              label: 'Minimum order',
              value: '${detail.minimumOrderQuantity} units',
            ),
          if (detail.warrantyInformation.isNotEmpty)
            _SpecRow(label: 'Warranty', value: detail.warrantyInformation),
          if (detail.shippingInformation.isNotEmpty)
            _SpecRow(label: 'Shipping', value: detail.shippingInformation),
          if (detail.returnPolicy.isNotEmpty)
            _SpecRow(label: 'Returns', value: detail.returnPolicy),
          if (detail.reviews.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Reviews', style: AppTextStyles.sectionHeading),
                const SizedBox(width: 8),
                RatingBadge(rating: detail.averageReviewRating, size: 13),
              ],
            ),
            const SizedBox(height: 4),
            for (final review in detail.reviews) ReviewTile(review: review),
          ],
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final ProductDetailModel detail;
  const _PriceBlock({required this.detail});

  @override
  Widget build(BuildContext context) {
    final product = detail.product;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          HelperFunction.price(product.discountedPrice),
          style: AppTextStyles.detailPrice,
        ),
        if (product.hasDiscount) ...[
          const SizedBox(width: 10),
          Text(
            HelperFunction.price(product.price),
            style: AppTextStyles.strikePrice.copyWith(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(DataConst.kLowBorderRadius),
            ),
            child: Text(
              HelperFunction.discountLabel(product.discountPercentage),
              style: AppTextStyles.badge,
            ),
          ),
        ],
      ],
    );
  }
}

class _StockLine extends StatelessWidget {
  final ProductDetailModel detail;
  const _StockLine({required this.detail});

  @override
  Widget build(BuildContext context) {
    final product = detail.product;
    final inStock = product.isInStock;
    final status = product.availabilityStatus.isNotEmpty
        ? product.availabilityStatus
        : (inStock ? 'In Stock' : 'Out of Stock');

    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: DataConst.kNormalIconSize,
          color: inStock ? AppColors.green : AppColors.red,
        ),
        const SizedBox(width: 6),
        Text(
          inStock ? '$status · ${product.stock} left' : status,
          style: AppTextStyles.label.copyWith(
            color: inStock ? AppColors.green : AppColors.red,
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.label),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.darkText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
