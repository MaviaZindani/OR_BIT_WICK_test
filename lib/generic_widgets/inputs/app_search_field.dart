import 'package:flutter/material.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';

/// Rounded search field at the top of the Explore screen. The clear button
/// only appears once there is text, so an empty field has no dead control.
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final String hintText;

  const AppSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.hintText = 'Search products, brands…',
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DataConst.kHighBorderRadius),
      borderSide: BorderSide.none,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.searchHint.copyWith(color: AppColors.darkText),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.searchFieldFill,
          hintText: hintText,
          hintStyle: AppTextStyles.searchHint,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.greyText,
            size: DataConst.kHighIconSize,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.greyText,
                    size: DataConst.kHighIconSize,
                  ),
                ),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DataConst.kHighBorderRadius),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: DataConst.kBorderNormalThickness,
            ),
          ),
        ),
      ),
    );
  }
}
