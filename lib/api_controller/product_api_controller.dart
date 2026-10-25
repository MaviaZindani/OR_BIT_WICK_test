import 'package:http/http.dart' as http;
import 'package:product_explorer/api_controller/api_guard.dart';
import 'package:product_explorer/enums/product_sort.dart';
import 'package:product_explorer/models/category_model.dart';
import 'package:product_explorer/models/product_page.dart';
import 'package:product_explorer/service/api_service/api_links.dart';
import 'package:product_explorer/service/api_service/api_services.dart';

/// The Explore screen - product grid, category row, search and sort.
///
/// Maps DummyJSON json onto models so [ProductsBloc] never sees a `Map`.
/// `ApiExceptions` from [ApiService] are allowed to propagate.
class ProductApiController with ApiGuard {
  /// Injected only by tests (a `MockClient`); production uses the shared
  /// client inside [ApiService].
  final http.Client? client;

  const ProductApiController({this.client});

  static const int pageSize = 20;

  /// Trims each list row to what the grid renders. The description, review
  /// list and dimensions only travel for the product the user opens.
  static const String listFields =
      'id,title,price,discountPercentage,rating,stock,brand,category,'
      'thumbnail,availabilityStatus';

  Future<List<CategoryModel>> getCategories() => guard(() async {
    final json = await ApiService.apiGetRequest(
      ApiLinks.categories,
      httpClint: client,
    );
    return (json as List)
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .where((c) => c.slug.isNotEmpty)
        .toList();
  });

  /// Browse mode: one server page, optionally scoped to a category. The
  /// category endpoint takes the same `limit` / `skip` / `sortBy` params as
  /// the plain list, so both share this path.
  Future<ProductPage> getProducts({
    String? category,
    ProductSort sort = ProductSort.relevance,
    int skip = 0,
  }) => guard(() async {
    final endPoint = category == null
        ? ApiLinks.products
        : ApiLinks.productsByCategory(category);
    final json = await ApiService.apiGetRequest(
      endPoint,
      queryParams: {
        'limit': '$pageSize',
        'skip': '$skip',
        'select': listFields,
        ...sort.queryParams,
      },
      httpClint: client,
    );
    return ProductPage.fromJson(json as Map<String, dynamic>);
  });

  /// Search mode. DummyJSON's search endpoint cannot be scoped to a category,
  /// so rather than paging through results and hiding the ones outside the
  /// chosen category (which would produce pages of nothing), this asks for
  /// every match at once (`limit=0`) and applies the category locally. The
  /// whole catalogue is under 200 rows and `select=` keeps each one small, so
  /// the full match set is cheaper than one TMDB-sized page.
  Future<ProductPage> searchProducts(
    String query, {
    String? category,
    ProductSort sort = ProductSort.relevance,
  }) => guard(() async {
    final json = await ApiService.apiGetRequest(
      ApiLinks.searchProducts,
      queryParams: {
        'q': query,
        'limit': '0',
        'select': listFields,
        ...sort.queryParams,
      },
      httpClint: client,
    );
    final page = ProductPage.fromJson(json as Map<String, dynamic>);
    if (category == null) return page;

    final matches = page.products.where((p) => p.category == category).toList();
    return ProductPage(
      products: matches,
      total: matches.length,
      limit: matches.length,
    );
  });
}
