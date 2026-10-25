import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/enums/product_sort.dart';

/// Single-choice sort picker. Returns the picked [ProductSort], or null when
/// dismissed, so the caller decides whether anything changed.
class SortBottomSheet extends StatelessWidget {
  final ProductSort current;

  const SortBottomSheet({super.key, required this.current});

  static Future<ProductSort?> show(
    BuildContext context, {
    required ProductSort current,
  }) {
    return showModalBottomSheet<ProductSort>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DataConst.kNormalBorderRadius * 2),
        ),
      ),
      builder: (_) => SortBottomSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Sort by', style: AppTextStyles.sectionHeading),
          ),
          RadioGroup<ProductSort>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in ProductSort.values)
                  RadioListTile<ProductSort>(
                    value: option,
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    title: Text(
                      option.label,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.darkText,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
