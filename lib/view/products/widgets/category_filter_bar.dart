import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_explorer/bloc/products/products_bloc.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/generic_widgets/chips/category_chip.dart';

/// Horizontal "All + categories" chip row. Driven by the category slice of
/// [ProductsState] only, so keystrokes and page loads never rebuild it.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({super.key});

  static const double height = 36;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: BlocBuilder<ProductsBloc, ProductsState>(
        buildWhen: (a, b) =>
            a.categories != b.categories ||
            a.categoryStatus != b.categoryStatus ||
            a.selectedCategory != b.selectedCategory,
        builder: (context, state) => switch (state.categoryStatus) {
          ProductsStatus.idle || ProductsStatus.loading => const _ChipRowLoader(),
          ProductsStatus.failure => _ChipRowError(
            onRetry: () => context.read<ProductsBloc>().add(
              const ProductsCategoriesRequested(),
            ),
          ),
          ProductsStatus.success => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: DataConst.kScreenHorizontalPadding * 2,
            ),
            itemCount: state.categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryChip(
                  label: 'All',
                  selected: state.selectedCategory == null,
                  onTap: () => context.read<ProductsBloc>().add(
                    const ProductsCategorySelected(null),
                  ),
                );
              }
              final category = state.categories[index - 1];
              return CategoryChip(
                label: category.name,
                selected: state.selectedCategory == category.slug,
                onTap: () => context.read<ProductsBloc>().add(
                  ProductsCategorySelected(category.slug),
                ),
              );
            },
          ),
        },
      ),
    );
  }
}

class _ChipRowLoader extends StatelessWidget {
  const _ChipRowLoader();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: DataConst.kScreenHorizontalPadding * 2,
      ),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, index) => Container(
        width: index == 0 ? 56 : 92,
        decoration: const ShapeDecoration(
          color: AppColors.chipFill,
          shape: StadiumBorder(),
        ),
      ),
    );
  }
}

/// The grid still works without chips, so a failed category fetch gets a
/// one-line retry rather than an error screen.
class _ChipRowError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ChipRowError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DataConst.kScreenHorizontalPadding * 2,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: DataConst.kNormalIconSize,
            color: AppColors.greyText,
          ),
          const SizedBox(width: 6),
          Text("Categories didn't load", style: AppTextStyles.label),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: AppTextStyles.label.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
