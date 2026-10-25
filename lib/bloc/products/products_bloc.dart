import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:product_explorer/api_controller/product_api_controller.dart';
import 'package:product_explorer/enums/product_sort.dart';
import 'package:product_explorer/models/category_model.dart';
import 'package:product_explorer/models/product_model.dart';
import 'package:product_explorer/models/product_page.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductApiController controller;

  static const debounceDuration = Duration(milliseconds: 350);

  ProductsBloc(this.controller) : super(const ProductsState()) {
    on<ProductsStarted>(_onStarted, transformer: restartable());
    on<ProductsCategoriesRequested>(
      _onCategoriesRequested,
      transformer: droppable(),
    );
    // restartable() cancels the previous keystroke's handler, which gives both
    // the debounce and the guard against an older response landing last.
    on<ProductsQueryChanged>(_onQueryChanged, transformer: restartable());
    on<ProductsSearchCleared>(_onSearchCleared, transformer: restartable());
    on<ProductsCategorySelected>(
      _onCategorySelected,
      transformer: restartable(),
    );
    on<ProductsSortChanged>(_onSortChanged, transformer: restartable());
    on<ProductsFiltersCleared>(_onFiltersCleared, transformer: restartable());
    // droppable(): while a page is loading, further scroll events are ignored
    // rather than queued.
    on<ProductsLoadMoreRequested>(_onLoadMore, transformer: droppable());
    on<ProductsRefreshed>(_onRefreshed, transformer: restartable());
  }

  Future<void> _onStarted(
    ProductsStarted event,
    Emitter<ProductsState> emit,
  ) async {
    add(const ProductsCategoriesRequested());
    await _reload(emit);
  }

  Future<void> _onCategoriesRequested(
    ProductsCategoriesRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(categoryStatus: ProductsStatus.loading));
    try {
      final categories = await controller.getCategories();
      if (emit.isDone) return;
      emit(
        state.copyWith(
          categories: categories,
          categoryStatus: ProductsStatus.success,
        ),
      );
    } catch (_) {
      if (emit.isDone) return;
      // The grid works without chips, so this never touches `status`; the
      // row renders a compact retry instead.
      emit(state.copyWith(categoryStatus: ProductsStatus.failure));
    }
  }

  Future<void> _onQueryChanged(
    ProductsQueryChanged event,
    Emitter<ProductsState> emit,
  ) async {
    if (event.query.trim() == state.query.trim()) return;

    emit(state.copyWith(query: event.query, status: ProductsStatus.loading));

    // Cancelled by restartable() the moment the next keystroke arrives, so no
    // request is ever made for an abandoned query.
    await Future<void>.delayed(debounceDuration);
    if (emit.isDone) return;

    await _reload(emit);
  }

  Future<void> _onSearchCleared(
    ProductsSearchCleared event,
    Emitter<ProductsState> emit,
  ) async {
    if (!state.isSearching) return;
    emit(state.copyWith(query: '', status: ProductsStatus.loading));
    await _reload(emit);
  }

  Future<void> _onCategorySelected(
    ProductsCategorySelected event,
    Emitter<ProductsState> emit,
  ) async {
    final clearing = event.slug == null || event.slug == state.selectedCategory;
    if (clearing && state.selectedCategory == null) return;

    emit(
      clearing
          ? state.copyWith(
              clearSelectedCategory: true,
              status: ProductsStatus.loading,
            )
          : state.copyWith(
              selectedCategory: event.slug,
              status: ProductsStatus.loading,
            ),
    );
    await _reload(emit);
  }

  Future<void> _onSortChanged(
    ProductsSortChanged event,
    Emitter<ProductsState> emit,
  ) async {
    if (event.sort == state.sort) return;
    emit(state.copyWith(sort: event.sort, status: ProductsStatus.loading));
    await _reload(emit);
  }

  Future<void> _onFiltersCleared(
    ProductsFiltersCleared event,
    Emitter<ProductsState> emit,
  ) async {
    if (!state.hasActiveFilters) return;
    emit(
      state.copyWith(
        query: '',
        clearSelectedCategory: true,
        sort: ProductSort.relevance,
        status: ProductsStatus.loading,
      ),
    );
    await _reload(emit);
  }

  Future<void> _onRefreshed(
    ProductsRefreshed event,
    Emitter<ProductsState> emit,
  ) async {
    // No loading status: RefreshIndicator shows its own spinner and the
    // current grid stays put underneath it.
    await _reload(emit, keepProductsOnFailure: true);
  }

  /// Fetches page one for the current filters. The snapshot taken before the
  /// await is compared after it: restartable() only cancels handlers of the
  /// *same* event, so a chip tap landing while a keystroke is in flight would
  /// otherwise be overwritten by the keystroke's response.
  Future<void> _reload(
    Emitter<ProductsState> emit, {
    bool keepProductsOnFailure = false,
  }) async {
    final filters = state.filters;
    try {
      final page = await _fetch(filters);
      if (emit.isDone || state.filters != filters) return;
      emit(
        state.copyWith(
          products: page.products,
          total: page.total,
          status: ProductsStatus.success,
          hasMore: !filters.isSearching && page.hasMore,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      );
    } catch (e) {
      if (emit.isDone || state.filters != filters) return;
      final keep = keepProductsOnFailure && state.products.isNotEmpty;
      emit(
        state.copyWith(
          status: keep ? ProductsStatus.success : ProductsStatus.failure,
          products: keep ? null : const [],
          total: keep ? null : 0,
          hasMore: keep ? null : false,
          isLoadingMore: false,
          loadMoreFailed: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<ProductPage> _fetch(ProductsFilters filters, {int skip = 0}) =>
      filters.isSearching
      ? controller.searchProducts(
          filters.query,
          category: filters.category,
          sort: filters.sort,
        )
      : controller.getProducts(
          category: filters.category,
          sort: filters.sort,
          skip: skip,
        );

  Future<void> _onLoadMore(
    ProductsLoadMoreRequested event,
    Emitter<ProductsState> emit,
  ) async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status != ProductsStatus.success) {
      return;
    }

    final filters = state.filters;
    final before = state.products;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));

    try {
      final page = await _fetch(filters, skip: before.length);
      if (emit.isDone || state.filters != filters) return;

      // The server can repeat a row across pages when the sort key ties.
      final seen = before.map((p) => p.id).toSet();
      emit(
        state.copyWith(
          products: [...before, ...page.products.where((p) => seen.add(p.id))],
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (emit.isDone || state.filters != filters) return;
      // A failed page 2 must not blank out the page 1 already on screen.
      emit(state.copyWith(isLoadingMore: false, loadMoreFailed: true));
    }
  }
}
