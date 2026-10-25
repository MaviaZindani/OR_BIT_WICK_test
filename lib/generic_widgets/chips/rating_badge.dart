import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/utils/helper_functions.dart';

/// "★ 4.6" - star plus one-decimal rating, used on cards and the detail
/// header.
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.amber, size: size + 4),
        const SizedBox(width: 2),
        Text(
          HelperFunction.rating(rating),
          style: AppTextStyles.label.copyWith(
            color: AppColors.darkText,
            fontSize: size,
          ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: AppTextStyles.label.copyWith(fontSize: size),
          ),
        ],
      ],
    );
  }
}
