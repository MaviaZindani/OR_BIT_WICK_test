import 'package:product_explorer/service/api_service/api_exception.dart';
import 'package:product_explorer/service/api_service/app_host.dart';

/// Wraps every api call so the caller only ever sees an [ApiExceptions].
///
/// [ApiService] already throws typed exceptions for network failures and
/// non-2xx statuses, and those carry DummyJSON's own `message` - they are
/// worth showing, so they pass straight through. What this adds is a net under
/// everything *after* the response arrives: the `as Map<String, dynamic>`
/// casts and the `fromJson` parsing. Without it a payload in an unexpected
/// shape reaches the error view as a raw Dart `TypeError`.
mixin ApiGuard {
  Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiExceptions {
      rethrow;
    } catch (_) {
      throw FetchDataException(AppHost.apiBadResponseMsg);
    }
  }
}
