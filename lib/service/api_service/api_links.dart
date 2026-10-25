import '../../enums/enum_of_enviroment_flavours.dart';

const EnumOfEnviromentFlavours currentEnvironment =
    EnumOfEnviromentFlavours.production;

class ApiLinks {
  /// Bare authority - `Uri.https` takes a host, not a full url.
  /// Backed by a nullable field rather than `late final`, which throws a
  /// LateInitializationError if `init` ever runs twice (e.g. two widget tests).
  static String? _baseURL;
  static String get baseURL => _baseURL ?? _productionURL;

  static void init({required EnumOfEnviromentFlavours environment}) {
    _baseURL = environment == EnumOfEnviromentFlavours.development
        ? _developmentURL
        : _productionURL;
  }

  //base URL
  static const String _developmentURL = "dummyjson.com";
  static const String _productionURL = "dummyjson.com";

  // endpoints
  static const String products = '/products';
  static const String searchProducts = '/products/search';
  static const String categories = '/products/categories';

  static String productsByCategory(String slug) => '/products/category/$slug';
  static String productDetail(int id) => '/products/$id';
}
