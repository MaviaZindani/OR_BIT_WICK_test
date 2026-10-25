import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/models/review_model.dart';
import 'package:product_explorer/utils/helper_functions.dart';

class ReviewTile extends StatelessWidget {
  final ReviewModel review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final date = HelperFunction.reviewDate(review.date);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.screenBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.darkText,
                  ),
                ),
              ),
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: AppColors.amber,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.comment,
            style: AppTextStyles.body.copyWith(height: 1.4),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(date, style: AppTextStyles.cardSubtitle),
          ],
        ],
      ),
    );
  }
}
