// Bloc behaviour that is invisible from the widget tree: pagination merging,
// the debounce / race guards that bloc_concurrency's transformers provide,
// and the filter-snapshot check that protects against cross-event races.
//
// `add` is fire-and-forget, so each step dispatches an event and then waits on
// the state stream for the emission it cares about.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/api_controller/product_api_controller.dart';
import 'package:product_explorer/api_controller/product_detail_api_controller.dart';
import 'package:product_explorer/bloc/product_detail/product_detail_bloc.dart';
import 'package:product_explorer/bloc/products/products_bloc.dart';
import 'package:product_explorer/enums/product_sort.dart';
import 'package:product_explorer/models/category_model.dart';
import 'package:product_explorer/models/product_detail_model.dart';
import 'package:product_explorer/models/product_model.dart';
import 'package:product_explorer/models/product_page.dart';
import 'package:product_explorer/service/api_service/api_exception.dart';

ProductModel _product(int id, {String category = 'beauty'}) =>
    ProductModel(id: id, title: 'Product $id', category: category);

/// Long enough for a dispatched event to be processed and settle.
Future<void> _settle([int ms = 30]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

class PagedApi extends ProductApiController {
  int listCalls = 0;
  int searchCalls = 0;
  bool failPageTwo = false;
  bool failCategories = false;
  bool failEverything = false;

  /// A real request is never instant. Without some latency a handler finishes
  /// before the next event is delivered, and droppable() has nothing to drop.
  final Duration latency;

  PagedApi({this.latency = const Duration(milliseconds: 20)});

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future<void>.delayed(latency);
    if (failCategories) throw ServiceUnavailableException();
    return const [
      CategoryModel(slug: 'beauty', name: 'Beauty'),
      CategoryModel(slug: 'laptops', name: 'Laptops'),
    ];
  }

  @override
  Future<ProductPage> getProducts({
    String? category,
    ProductSort sort = ProductSort.relevance,
    int skip = 0,
  }) async {
    listCalls++;
    await Future<void>.delayed(latency);
    if (failEverything) throw FetchDataException('offline');
    if (skip > 0 && failPageTwo) throw FetchDataException('page 2 exploded');
    // Page 2 repeats product 2 on purpose, to prove it is de-duplicated.
    return skip == 0
        ? ProductPage(products: [_product(1), _product(2)], total: 5)
        : ProductPage(
            products: [_product(2), _product(3), _product(4)],
            total: 5,
            skip: 2,
          );
  }

  @override
  Future<ProductPage> searchProducts(
    String query, {
    String? category,
    ProductSort sort = ProductSort.relevance,
  }) async {
    searchCalls++;
    await Future<void>.delayed(latency);
    if (failEverything) throw FetchDataException('offline');
    return ProductPage(products: [_product(10)], total: 1);
  }
}

/// Hands back futures the test completes by hand, and records every query the
/// bloc actually asked for.
class BlockingApi extends PagedApi {
  final Map<String, Completer<ProductPage>> pending = {};
  final List<String> queriesSeen = [];

  @override
  Future<ProductPage> searchProducts(
    String query, {
    String? category,
    ProductSort sort = ProductSort.relevance,
  }) {
    queriesSeen.add(query);
    return (pending[query] ??= Completer<ProductPage>()).future;
  }

  void complete(String query, List<int> ids) => pending[query]!.complete(
    ProductPage(total: ids.length, products: ids.map(_product).toList()),
  );
}

Future<ProductsState> _loaded(ProductsBloc bloc) => bloc.stream.firstWhere(
  (s) => s.status == ProductsStatus.success && !s.isLoadingMore,
);

void main() {
  group('ProductsBloc start', () {
    test('loads categories and the first page independently', () async {
      final bloc = ProductsBloc(PagedApi());
      bloc.add(const ProductsStarted());

      final state = await bloc.stream.firstWhere(
        (s) =>
            s.status == ProductsStatus.success &&
            s.categoryStatus == ProductsStatus.success,
      );

      expect(state.products.map((p) => p.id), [1, 2]);
      expect(state.total, 5);
      expect(state.hasMore, isTrue);
      expect(state.categories, hasLength(2));
      await bloc.close();
    });

    test('a failed category fetch does not take the grid down', () async {
      final bloc = ProductsBloc(PagedApi()..failCategories = true);
      bloc.add(const ProductsStarted());

      final state = await bloc.stream.firstWhere(
        (s) =>
            s.status == ProductsStatus.success &&
            s.categoryStatus == ProductsStatus.failure,
      );

      expect(state.products, isNotEmpty);
      expect(state.categories, isEmpty);
      await bloc.close();
    });

    test('a failed first page lands in failure with the message', () async {
      final bloc = ProductsBloc(PagedApi()..failEverything = true);
      bloc.add(const ProductsStarted());

      final state = await bloc.stream.firstWhere(
        (s) => s.status == ProductsStatus.failure,
      );

      expect(state.errorMessage, contains('offline'));
      expect(state.products, isEmpty);
      await bloc.close();
    });
  });

  group('ProductsBloc pagination', () {
    test('load more appends the next page and drops repeats', () async {
      final bloc = ProductsBloc(PagedApi());
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsLoadMoreRequested());
      final merged = await _loaded(bloc);

      // 2 + 3 fetched, but product 2 appears in both pages.
      expect(merged.products.map((p) => p.id), [1, 2, 3, 4]);
      expect(merged.hasMore, isFalse);
      await bloc.close();
    });

    test('a failed second page keeps page one and flags a retry', () async {
      final bloc = ProductsBloc(PagedApi()..failPageTwo = true);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsLoadMoreRequested());
      final after = await bloc.stream.firstWhere((s) => s.loadMoreFailed);

      expect(after.products.map((p) => p.id), [1, 2]);
      expect(after.status, ProductsStatus.success);
      expect(after.isLoadingMore, isFalse);
      await bloc.close();
    });

    test('scroll events while a page is in flight are dropped', () async {
      final api = PagedApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);
      expect(api.listCalls, 1);

      bloc.add(const ProductsLoadMoreRequested());
      bloc.add(const ProductsLoadMoreRequested());
      bloc.add(const ProductsLoadMoreRequested());
      await _loaded(bloc);
      await _settle();

      expect(api.listCalls, 2);
      await bloc.close();
    });

    test('search mode never pages', () async {
      final api = PagedApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsQueryChanged('x'));
      final searched = await bloc.stream.firstWhere(
        (s) => s.status == ProductsStatus.success && s.isSearching,
      );
      expect(searched.hasMore, isFalse);

      bloc.add(const ProductsLoadMoreRequested());
      await _settle();
      expect(api.searchCalls, 1);
      expect(api.listCalls, 1);
      await bloc.close();
    });
  });

  group('ProductsBloc search', () {
    test('rapid keystrokes produce one request, for the last query', () async {
      final api = PagedApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsQueryChanged('p'));
      bloc.add(const ProductsQueryChanged('ph'));
      bloc.add(const ProductsQueryChanged('pho'));

      final state = await bloc.stream.firstWhere(
        (s) => s.status == ProductsStatus.success && s.query == 'pho',
      );

      expect(api.searchCalls, 1);
      expect(state.products.single.id, 10);
      await bloc.close();
    });

    test('a stale response for an older query is ignored', () async {
      final api = BlockingApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsQueryChanged('old'));
      await _settle(ProductsBloc.debounceDuration.inMilliseconds + 30);
      expect(api.queriesSeen, ['old']);

      // The user keeps typing while "old" is still in flight.
      bloc.add(const ProductsQueryChanged('new'));
      await _settle(ProductsBloc.debounceDuration.inMilliseconds + 30);
      expect(api.queriesSeen, ['old', 'new']);

      // "old" answers last - and must not win.
      api.complete('new', [2]);
      await _settle();
      api.complete('old', [1]);
      await _settle();

      expect(bloc.state.query, 'new');
      expect(bloc.state.products.map((p) => p.id), [2]);
      await bloc.close();
    });

    test('a chip tap landing mid-search is not overwritten by it', () async {
      final api = BlockingApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsQueryChanged('phone'));
      await _settle(ProductsBloc.debounceDuration.inMilliseconds + 30);
      expect(api.queriesSeen, ['phone']);

      // Different event type, so restartable() cannot cancel the first one.
      bloc.add(const ProductsCategorySelected('laptops'));
      await _settle();
      expect(api.queriesSeen, ['phone', 'phone']);

      api.complete('phone', [1]);
      await _settle();

      // Both requests resolved from the same completer, but the first
      // handler's snapshot (no category) no longer matches the state.
      expect(bloc.state.selectedCategory, 'laptops');
      expect(bloc.state.status, ProductsStatus.success);
      await bloc.close();
    });

    test('clearing the search returns to the browse page', () async {
      final api = PagedApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsQueryChanged('x'));
      await bloc.stream.firstWhere(
        (s) => s.status == ProductsStatus.success && s.isSearching,
      );

      bloc.add(const ProductsSearchCleared());
      final back = await bloc.stream.firstWhere(
        (s) => s.status == ProductsStatus.success && !s.isSearching,
      );

      expect(back.products.map((p) => p.id), [1, 2]);
      expect(back.hasMore, isTrue);
      expect(api.listCalls, 2);
      await bloc.close();
    });
  });

  group('ProductsBloc filters', () {
    test('tapping the selected chip again clears it', () async {
      final bloc = ProductsBloc(PagedApi());
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsCategorySelected('beauty'));
      final on = await _loaded(bloc);
      expect(on.selectedCategory, 'beauty');

      bloc.add(const ProductsCategorySelected('beauty'));
      final off = await _loaded(bloc);
      expect(off.selectedCategory, isNull);
      await bloc.close();
    });

    test('clear filters resets query, category and sort together', () async {
      final bloc = ProductsBloc(PagedApi());
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsCategorySelected('beauty'));
      await _loaded(bloc);
      bloc.add(const ProductsSortChanged(ProductSort.priceLowToHigh));
      await _loaded(bloc);
      expect(bloc.state.activeFilterCount, 2);

      bloc.add(const ProductsFiltersCleared());
      final cleared = await _loaded(bloc);

      expect(cleared.hasActiveFilters, isFalse);
      expect(cleared.sort, ProductSort.relevance);
      await bloc.close();
    });

    test('re-selecting the current sort makes no request', () async {
      final api = PagedApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      bloc.add(const ProductsSortChanged(ProductSort.relevance));
      await _settle();
      expect(api.listCalls, 1);
      await bloc.close();
    });
  });

  group('ProductsBloc refresh', () {
    test('a failed refresh keeps the products and reports via message', () async {
      final api = PagedApi();
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await _loaded(bloc);

      api.failEverything = true;
      bloc.add(const ProductsRefreshed());
      final after = await bloc.stream.firstWhere((s) => s.errorMessage != null);

      expect(after.status, ProductsStatus.success);
      expect(after.products.map((p) => p.id), [1, 2]);
      expect(after.errorMessage, contains('offline'));
      await bloc.close();
    });

    test('refresh from the error view recovers to success', () async {
      final api = PagedApi()..failEverything = true;
      final bloc = ProductsBloc(api);
      bloc.add(const ProductsStarted());
      await bloc.stream.firstWhere((s) => s.status == ProductsStatus.failure);

      api.failEverything = false;
      bloc.add(const ProductsRefreshed());
      final recovered = await _loaded(bloc);

      expect(recovered.products, isNotEmpty);
      expect(recovered.errorMessage, isNull);
      await bloc.close();
    });
  });

  group('ProductDetailBloc', () {
    test('error then retry', () async {
      var calls = 0;
      final api = _DetailApi(() async {
        calls++;
        if (calls == 1) throw ApiNotFoundException("Product with id '1' not found");
        return const ProductDetailModel(
          product: ProductModel(id: 1, title: 'Found'),
        );
      });
      final bloc = ProductDetailBloc(api);

      bloc.add(const ProductDetailRequested(1));
      final error =
          await bloc.stream.firstWhere((s) => s is ProductDetailError)
              as ProductDetailError;
      expect(error.message, contains('not found'));

      bloc.add(const ProductDetailRequested(1));
      final loaded =
          await bloc.stream.firstWhere((s) => s is ProductDetailLoaded)
              as ProductDetailLoaded;
      expect(loaded.detail.product.title, 'Found');
      await bloc.close();
    });
  });
}

class _DetailApi extends ProductDetailApiController {
  final Future<ProductDetailModel> Function() handler;
  const _DetailApi(this.handler);

  @override
  Future<ProductDetailModel> getProduct(int id) => handler();
}
