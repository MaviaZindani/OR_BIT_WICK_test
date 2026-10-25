import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_explorer/bloc/products/products_bloc.dart';
import 'package:product_explorer/constant/app_colors.dart';
import 'package:product_explorer/constant/data_const.dart';
import 'package:product_explorer/constant/design_const.dart';
import 'package:product_explorer/enums/product_sort.dart';
import 'package:product_explorer/generic_widgets/inputs/app_search_field.dart';
import 'package:product_explorer/view/products/widgets/category_filter_bar.dart';
import 'package:product_explorer/view/products/widgets/product_grid_view.dart';
import 'package:product_explorer/view/products/widgets/sort_bottom_sheet.dart';

/// The Explore screen: search field and category row in the app bar, the
/// product grid underneath. Browse, search and filter are all one screen -
/// the bloc swaps what the grid shows, and the chips / query stay put.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const double _sidePadding = DataConst.kScreenHorizontalPadding * 2;

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onClearTapped() {
    _controller.clear();
    context.read<ProductsBloc>().add(const ProductsSearchCleared());
    _focusNode.requestFocus();
  }

  /// The empty state's "Clear filters" resets the bloc; the text field is
  /// not bloc-driven, so it is cleared here to match.
  void _onFiltersCleared() {
    _controller.clear();
    _focusNode.unfocus();
    context.read<ProductsBloc>().add(const ProductsFiltersCleared());
  }

  Future<void> _openSort() async {
    final bloc = context.read<ProductsBloc>();
    final picked = await SortBottomSheet.show(context, current: bloc.state.sort);
    if (picked != null) bloc.add(ProductsSortChanged(picked));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductsBloc, ProductsState>(
      // A refresh that fails while products are still on screen is reported
      // here; a failure with nothing to show gets the full error view.
      listenWhen: (a, b) =>
          b.errorMessage != null &&
          b.status == ProductsStatus.success &&
          a.errorMessage != b.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text("Couldn't refresh: ${state.errorMessage}"),
            ),
          );
      },
      child: GestureDetector(
        // Tapping anywhere outside the field drops the keyboard.
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.screenBackground,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: _sidePadding,
            title: Text('Explore', style: AppTextStyles.screenTitle),
            actions: [
              BlocBuilder<ProductsBloc, ProductsState>(
                buildWhen: (a, b) => a.sort != b.sort,
                builder: (context, state) => IconButton(
                  tooltip: 'Sort',
                  onPressed: _openSort,
                  icon: Badge(
                    isLabelVisible: state.sort != ProductSort.relevance,
                    backgroundColor: AppColors.primary,
                    smallSize: 8,
                    child: const Icon(
                      Icons.swap_vert_rounded,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DataConst.kScreenHorizontalPadding),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_SearchHeader.height),
              child: _SearchHeader(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _sidePadding,
                      ),
                      child: AppSearchField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: (q) => context.read<ProductsBloc>().add(
                          ProductsQueryChanged(q),
                        ),
                        onSubmitted: (_) => _focusNode.unfocus(),
                        onClear: _onClearTapped,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const CategoryFilterBar(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          body: ProductGridView(onClearFilters: _onFiltersCleared),
        ),
      ),
    );
  }
}

/// The app bar's bottom slot needs a fixed height up front; this is the
/// search field (44) + spacing + chip row (36) + spacing.
class _SearchHeader extends StatelessWidget {
  static const double height = 44 + 10 + 36 + 8;
  final Widget child;
  const _SearchHeader({required this.child});

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.background, child: child);
}
