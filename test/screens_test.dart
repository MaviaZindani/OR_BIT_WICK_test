// Layout tests for the two screens, driven by stub api controllers.
//
// These verify structure and catch RenderFlex overflows without a network.
// Products are given null image urls on purpose so AppNetworkImage takes its
// fallback branch and nothing reaches the network.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/api_controller/product_api_controller.dart';
import 'package:product_explorer/api_controller/product_detail_api_controller.dart';
import 'package:product_explorer/arguments/product_detail_args.dart';
import 'package:product_explorer/bloc/product_detail/product_detail_bloc.dart';
import 'package:product_explorer/bloc/products/products_bloc.dart';
import 'package:product_explorer/enums/enum_of_enviroment_flavours.dart';
import 'package:product_explorer/enums/product_sort.dart';
import 'package:product_explorer/generic_widgets/cards/product_card.dart';
import 'package:product_explorer/generic_widgets/chips/category_chip.dart';
import 'package:product_explorer/generic_widgets/states/app_state_views.dart';
import 'package:product_explorer/models/category_model.dart';
import 'package:product_explorer/models/product_detail_model.dart';
import 'package:product_explorer/models/product_model.dart';
import 'package:product_explorer/models/product_page.dart';
import 'package:product_explorer/models/review_model.dart';
import 'package:product_explorer/routes/app_pages.dart';
import 'package:product_explorer/service/api_service/api_exception.dart';
import 'package:product_explorer/service/api_service/api_links.dart';
import 'package:product_explorer/view/product_detail/product_detail_screen.dart';
import 'package:product_explorer/view/product_detail/widgets/review_tile.dart';
import 'package:product_explorer/view/products/products_screen.dart';

ProductModel _product(int id, String title, {double discount = 0, int stock = 5}) =>
    ProductModel(
      id: id,
      title: title,
      brand: 'Brand $id',
      category: 'beauty',
      price: 19.99,
      discountPercentage: discount,
      rating: 4.2,
      stock: stock,
    );

class StubProductApi extends ProductApiController {
  bool failList = false;
  bool emptySearch = true;

  @override
  Future<List<CategoryModel>> getCategories() async => const [
    CategoryModel(slug: 'beauty', name: 'Beauty'),
    CategoryModel(slug: 'laptops', name: 'Laptops'),
  ];

  @override
  Future<ProductPage> getProducts({
    String? category,
    ProductSort sort = ProductSort.relevance,
    int skip = 0,
  }) async {
    if (failList) throw FetchDataException('No Internet Connection.');
    return ProductPage(
      total: 3,
      products: [
        _product(1, 'Essence Mascara Lash Princess', discount: 10.48),
        _product(2, 'Eyeshadow Palette with Mirror', stock: 0),
        _product(3, 'Powder Canister'),
      ],
    );
  }

  @override
  Future<ProductPage> searchProducts(
    String query, {
    String? category,
    ProductSort sort = ProductSort.relevance,
  }) async => emptySearch
      ? const ProductPage()
      : ProductPage(total: 1, products: [_product(9, 'Match')]);
}

class StubDetailApi extends ProductDetailApiController {
  @override
  Future<ProductDetailModel> getProduct(int id) async => ProductDetailModel(
    product: ProductModel(
      id: id,
      title: 'Essence Mascara Lash Princess',
      description: 'A popular mascara known for its volumizing effect. ' * 3,
      brand: 'Essence',
      category: 'beauty',
      price: 9.99,
      discountPercentage: 10.48,
      rating: 2.56,
      stock: 99,
      availabilityStatus: 'In Stock',
      tags: const ['beauty', 'mascara'],
    ),
    sku: 'BEA-ESS-ESS-001',
    warrantyInformation: '1 week warranty',
    shippingInformation: 'Ships in 3-5 business days',
    returnPolicy: 'No return policy',
    dimensions: const Dimensions(width: 15.14, height: 13.08, depth: 22.99),
    reviews: [
      ReviewModel(
        rating: 3,
        comment: 'Would not recommend!',
        reviewerName: 'Eleanor Collins',
        date: DateTime(2025, 4, 30),
      ),
      const ReviewModel(rating: 5, comment: 'Great', reviewerName: 'Lucas'),
    ],
  );
}

Widget _app(Widget child, {required StubProductApi productApi}) =>
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProductApiController>.value(value: productApi),
        RepositoryProvider<ProductDetailApiController>(
          create: (_) => StubDetailApi(),
        ),
      ],
      // Real route table, so a card tap pushes the real detail route.
      child: MaterialApp(
        home: child,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );

Widget _explore(StubProductApi api) => _app(
  BlocProvider(
    create: (context) =>
        ProductsBloc(api)..add(const ProductsStarted()),
    child: const ProductsScreen(),
  ),
  productApi: api,
);

void main() {
  late StubProductApi productApi;

  setUpAll(() {
    ApiLinks.init(environment: EnumOfEnviromentFlavours.production);
  });

  setUp(() => productApi = StubProductApi());

  group('Explore screen', () {
    testWidgets('renders a card per product, the count and the chips', (
      tester,
    ) async {
      await tester.pumpWidget(_explore(productApi));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ProductCard), findsNWidgets(3));
      expect(find.text('3 products'), findsOneWidget);
      expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
      // All + 2 categories
      expect(find.byType(CategoryChip), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Laptops'), findsOneWidget);
    });

    testWidgets('shows the discount badge and the out-of-stock scrim', (
      tester,
    ) async {
      await tester.pumpWidget(_explore(productApi));
      await tester.pump();
      await tester.pump();

      expect(find.text('-10%'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      // Discounted price next to the struck original.
      expect(find.text(r'$17.90'), findsOneWidget);
      expect(find.text(r'$19.99'), findsNWidgets(3));
    });

    testWidgets('a failed load shows the error view and retry recovers', (
      tester,
    ) async {
      productApi.failList = true;
      await tester.pumpWidget(_explore(productApi));
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('No Internet Connection.'), findsOneWidget);

      productApi.failList = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ProductCard), findsNWidgets(3));
    });

    testWidgets('an empty search shows the empty view with clear filters', (
      tester,
    ) async {
      await tester.pumpWidget(_explore(productApi));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(ProductsBloc.debounceDuration);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AppEmptyView), findsOneWidget);
      // The query is echoed in the empty message (the field also holds it).
      expect(
        find.descendant(
          of: find.byType(AppEmptyView),
          matching: find.textContaining('zzz'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear filters'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(ProductCard), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('tapping a card opens the detail with a Hero', (
      tester,
    ) async {
      await tester.pumpWidget(_explore(productApi));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Powder Canister'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });
  });

  group('Product detail screen', () {
    Widget detail() => _app(
      BlocProvider(
        create: (_) =>
            ProductDetailBloc(StubDetailApi())
              ..add(const ProductDetailRequested(1)),
        child: const ProductDetailScreen(
          args: ProductDetailArgs(
            productId: 1,
            title: 'Essence Mascara Lash Princess',
          ),
        ),
      ),
      productApi: productApi,
    );

    testWidgets('renders price, stock, specs and reviews', (tester) async {
      await tester.pumpWidget(detail());
      await tester.pump();
      await tester.pump();

      expect(find.text(r'$8.94'), findsOneWidget);
      expect(find.text(r'$9.99'), findsOneWidget);
      expect(find.text('In Stock · 99 left'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('15.1 × 13.1 × 23 cm'), findsOneWidget);
      expect(find.text('1 week warranty'), findsOneWidget);
      expect(find.byType(ReviewTile), findsNWidgets(2));
      expect(find.text('Eleanor Collins'), findsOneWidget);
    });

    testWidgets('wide layout puts the gallery beside the info', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(detail());
      await tester.pump();
      await tester.pump();

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Description'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
