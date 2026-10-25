import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_explorer/arguments/product_detail_args.dart';
import 'package:product_explorer/bloc/products/products_bloc.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/generic_widgets/cards/product_card.dart';
import 'package:product_explorer/generic_widgets/states/app_state_views.dart';
import 'package:product_explorer/routes/app_pages.dart';
import 'package:product_explorer/utils/helper_functions.dart';
import 'package:product_explorer/utils/screen_halper.dart';

/// The Explore body: loader / error / empty / grid, with infinite scroll in
/// browse mode and pull-to-refresh throughout.
class ProductGridView extends StatefulWidget {
  final VoidCallback onClearFilters;

  const ProductGridView({super.key, required this.onClearFilters});

  @override
  State<ProductGridView> createState() => _ProductGridViewState();
}

class _ProductGridViewState extends State<ProductGridView> {
  final _controller = ScrollController();

  /// How close to the bottom the user gets before the next page is requested.
  static const _loadMoreThreshold = 400.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // droppable() on the bloc discards this while a page is in flight, and
      // the handler returns early when there is no next page.
      context.read<ProductsBloc>().add(const ProductsLoadMoreRequested());
    }
  }

  Future<void> _refresh() {
    final bloc = context.read<ProductsBloc>();
    bloc.add(const ProductsRefreshed());
    // Keep the indicator up until the bloc settles on a non-loading state.
    return bloc.stream
        .firstWhere((s) => s.status != ProductsStatus.loading)
        .then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.products != b.products ||
          a.total != b.total ||
          a.isLoadingMore != b.isLoadingMore ||
          a.loadMoreFailed != b.loadMoreFailed ||
          a.hasActiveFilters != b.hasActiveFilters,
      builder: (context, state) {
        switch (state.status) {
          case ProductsStatus.idle:
          case ProductsStatus.loading:
            return const AppLoader();

          case ProductsStatus.failure:
            return AppErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () =>
                  context.read<ProductsBloc>().add(const ProductsRefreshed()),
            );

          case ProductsStatus.success:
            if (state.products.isEmpty) {
              return AppEmptyView(
                title: 'No products found',
                message: state.isSearching
                    ? 'Nothing matches "${state.query.trim()}"'
                          '${state.selectedCategory != null ? ' in this category' : ''}.'
                    : 'There is nothing in this category yet.',
                actionLabel: state.hasActiveFilters ? 'Clear filters' : null,
                onAction: state.hasActiveFilters ? widget.onClearFilters : null,
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: _Grid(controller: _controller, state: state),
            );
        }
      },
    );
  }
}

class _Grid extends StatelessWidget {
  final ScrollController controller;
  final ProductsState state;

  const _Grid({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    const side = DataConst.kScreenHorizontalPadding * 2;
    final columns = ScreenHelper.gridColumns(
      ScreenHelper.getScreenWidth(context),
    );

    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(side, 12, side, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              // The server's total, not products.length - a page caps at 20.
              HelperFunction.productCount(state.total),
              style: AppTextStyles.label,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(side, 8, side, 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.56,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.productDetailScreen,
                    arguments: ProductDetailArgs(
                      productId: product.id,
                      title: product.title,
                      imageUrl: product.imageUrl,
                    ),
                  ),
                );
              },
              childCount: state.products.length,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            side,
            8,
            side,
            DataConst.kScreenBottomPadding * 3,
          ),
          sliver: SliverToBoxAdapter(child: _Footer(state: state)),
        ),
      ],
    );
  }
}

/// Below the last row: a spinner while page N+1 loads, a retry when it
/// failed, nothing otherwise.
class _Footer extends StatelessWidget {
  final ProductsState state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: AppLoader(),
      );
    }
    if (state.loadMoreFailed) {
      return Center(
        child: TextButton.icon(
          onPressed: () => context.read<ProductsBloc>().add(
            const ProductsLoadMoreRequested(),
          ),
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          label: Text(
            "Couldn't load more. Tap to retry",
            style: AppTextStyles.label.copyWith(color: AppColors.primary),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
