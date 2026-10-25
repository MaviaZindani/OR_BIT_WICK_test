// The api controllers against a MockClient, so the real url building, json
// decoding, status handling and model mapping all run - only the socket is
// faked.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_explorer/api_controller/product_api_controller.dart';
import 'package:product_explorer/api_controller/product_detail_api_controller.dart';
import 'package:product_explorer/enums/enum_of_enviroment_flavours.dart';
import 'package:product_explorer/enums/product_sort.dart';
import 'package:product_explorer/service/api_service/api_exception.dart';
import 'package:product_explorer/service/api_service/api_links.dart';

Map<String, dynamic> _product(int id, String category) => {
  'id': id,
  'title': 'Product $id',
  'category': category,
  'price': 10.0 * id,
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {
      'content-type': 'application/json',
    });

void main() {
  setUpAll(() {
    ApiLinks.init(environment: EnumOfEnviromentFlavours.production);
  });

  group('getProducts', () {
    test('hits /products with paging, select and sort params', () async {
      late Uri seen;
      final api = ProductApiController(
        client: MockClient((request) async {
          seen = request.url;
          return _json({
            'products': [_product(1, 'beauty')],
            'total': 1,
            'skip': 0,
            'limit': 20,
          });
        }),
      );

      final page = await api.getProducts(
        sort: ProductSort.priceHighToLow,
        skip: 40,
      );

      expect(seen.host, 'dummyjson.com');
      expect(seen.path, '/products');
      expect(seen.queryParameters['limit'], '20');
      expect(seen.queryParameters['skip'], '40');
      expect(seen.queryParameters['sortBy'], 'price');
      expect(seen.queryParameters['order'], 'desc');
      expect(seen.queryParameters['select'], contains('thumbnail'));
      expect(page.products.single.title, 'Product 1');
    });

    test('a category routes to /products/category/{slug}', () async {
      late Uri seen;
      final api = ProductApiController(
        client: MockClient((request) async {
          seen = request.url;
          return _json({'products': [], 'total': 0, 'skip': 0, 'limit': 20});
        }),
      );

      await api.getProducts(category: 'mobile-accessories');

      expect(seen.path, '/products/category/mobile-accessories');
      // Relevance adds no sort params.
      expect(seen.queryParameters.containsKey('sortBy'), isFalse);
    });
  });

  group('searchProducts', () {
    test('asks for every match and applies the category locally', () async {
      late Uri seen;
      final api = ProductApiController(
        client: MockClient((request) async {
          seen = request.url;
          return _json({
            'products': [
              _product(1, 'smartphones'),
              _product(2, 'mobile-accessories'),
              _product(3, 'smartphones'),
            ],
            'total': 3,
            'skip': 0,
            'limit': 3,
          });
        }),
      );

      final page = await api.searchProducts(
        'phone',
        category: 'smartphones',
      );

      expect(seen.path, '/products/search');
      expect(seen.queryParameters['q'], 'phone');
      expect(seen.queryParameters['limit'], '0');
      expect(page.products.map((p) => p.id), [1, 3]);
      // The header count reflects what is actually shown.
      expect(page.total, 2);
      expect(page.hasMore, isFalse);
    });

    test('without a category the server page passes through', () async {
      final api = ProductApiController(
        client: MockClient(
          (_) async => _json({
            'products': [_product(1, 'a'), _product(2, 'b')],
            'total': 2,
            'skip': 0,
            'limit': 2,
          }),
        ),
      );

      final page = await api.searchProducts('x');
      expect(page.products, hasLength(2));
      expect(page.total, 2);
    });
  });

  group('getCategories', () {
    test('maps slug + name and drops malformed rows', () async {
      final api = ProductApiController(
        client: MockClient(
          (_) async => _json([
            {'slug': 'beauty', 'name': 'Beauty', 'url': 'https://x'},
            {'name': 'no slug'},
            'not even a map',
          ]),
        ),
      );

      final categories = await api.getCategories();
      expect(categories, hasLength(1));
      expect(categories.single.slug, 'beauty');
      expect(categories.single.name, 'Beauty');
    });
  });

  group('failure handling', () {
    test("a 404 carries DummyJSON's own message", () async {
      final api = ProductDetailApiController(
        client: MockClient(
          (_) async => _json({"message": "Product with id '999' not found"}, 404),
        ),
      );

      await expectLater(
        api.getProduct(999),
        throwsA(
          isA<ApiNotFoundException>().having(
            (e) => e.toString(),
            'message',
            contains("id '999' not found"),
          ),
        ),
      );
    });

    test('a 500 surfaces as InternalServerException', () async {
      final api = ProductApiController(
        client: MockClient((_) async => http.Response('boom', 500)),
      );

      await expectLater(
        api.getProducts(),
        throwsA(isA<InternalServerException>()),
      );
    });

    test('a connection failure becomes a readable FetchDataException', () async {
      final api = ProductApiController(
        client: MockClient((_) async => throw http.ClientException('reset')),
      );

      await expectLater(
        api.getProducts(),
        throwsA(
          isA<FetchDataException>().having(
            (e) => e.toString(),
            'message',
            contains('No Internet'),
          ),
        ),
      );
    });

    test('a payload in the wrong shape is caught by ApiGuard', () async {
      // 200 OK, but a list where a map was expected. Not a raw TypeError:
      // the error view shows a readable message.
      final api = ProductApiController(
        client: MockClient((_) async => _json([1, 2, 3])),
      );

      await expectLater(
        api.getProducts(),
        throwsA(
          isA<FetchDataException>().having(
            (e) => e.toString(),
            'message',
            contains('Unexpected response'),
          ),
        ),
      );
    });

    test('an unparseable body on a 200 is also guarded', () async {
      final api = ProductApiController(
        client: MockClient((_) async => http.Response('<html>', 200)),
      );

      await expectLater(api.getProducts(), throwsA(isA<ApiExceptions>()));
    });
  });
}
