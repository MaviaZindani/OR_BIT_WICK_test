import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:product_explorer/service/api_service/api_exception.dart';
import 'api_links.dart';
import 'app_host.dart';

class ApiService {
  static final client = http.Client();

  /// Builds a DummyJSON uri. [ApiLinks.baseURL] is a bare authority, so it
  /// goes through [Uri.https] rather than being concatenated onto the
  /// endpoint. An empty param map is passed as null, otherwise `Uri.https`
  /// appends a dangling `?`.
  static Uri _uri(String endPoint, [Map<String, String>? extraParams]) {
    final params = {...AppHost.apiQueryParams(), ...?extraParams};
    return Uri.https(ApiLinks.baseURL, endPoint, params.isEmpty ? null : params);
  }

  static Future<dynamic> apiGetRequest(
    String endPoint, {
    Map<String, String>? queryParams,
    http.Client? httpClint,
  }) async {
    dynamic response;
    final uri = _uri(endPoint, queryParams);

    try {
      response = await (httpClint ?? client)
          .get(uri, headers: AppHost.apiHeaders())
          .timeout(AppHost.requestTimeout);
    } on TimeoutException {
      throw FetchDataException(AppHost.timeoutMsg);
    } on HttpException {
      throw FetchDataException(AppHost.apiExceptionMsg);
    } on SocketException {
      throw FetchDataException(AppHost.noInternetMsg);
    } on http.ClientException {
      // Thrown by `http` on platforms where dart:io's SocketException never
      // surfaces (e.g. a mid-flight connection drop).
      throw FetchDataException(AppHost.noInternetMsg);
    } catch (e) {
      rethrow;
    }
    return _returnResponse(response, endPoint: endPoint, method: Method.GET);
  }

  static Future<dynamic> apiPostRequest(
    String endPoint,
    dynamic requestBody, {
    http.Client? httpClint,
  }) async {
    dynamic response;
    final uri = _uri(endPoint);
    try {
      response = await (httpClint ?? client)
          .post(uri, headers: AppHost.apiHeaders(), body: requestBody)
          .timeout(AppHost.requestTimeout);
    } on TimeoutException {
      throw FetchDataException(AppHost.timeoutMsg);
    } on SocketException {
      throw FetchDataException(AppHost.noInternetMsg);
    } on HttpException {
      throw FetchDataException(AppHost.apiExceptionMsg);
    }

    return _returnResponse(
      response,
      endPoint: endPoint,
      method: Method.POST,
      requestBody: requestBody,
    );
  }

  static Future<dynamic> apiPutRequest(
    String endPoint,
    dynamic requestBody,
  ) async {
    dynamic response;
    final uri = _uri(endPoint);
    try {
      response = await client
          .put(uri, body: requestBody, headers: AppHost.apiHeaders())
          .timeout(AppHost.requestTimeout);
    } on TimeoutException {
      throw FetchDataException(AppHost.timeoutMsg);
    } on SocketException {
      throw FetchDataException(AppHost.noInternetMsg);
    }

    return _returnResponse(
      response,
      endPoint: endPoint,
      method: Method.PUT,
      requestBody: requestBody,
    );
  }

  static Future<dynamic> apiPatchRequest(
    String endPoint, {
    dynamic requestBody,
  }) async {
    dynamic response;
    final uri = _uri(endPoint);
    try {
      response = await client
          .patch(uri, headers: AppHost.apiHeaders(), body: requestBody)
          .timeout(AppHost.requestTimeout);
    } on TimeoutException {
      throw FetchDataException(AppHost.timeoutMsg);
    } on SocketException {
      throw FetchDataException(AppHost.noInternetMsg);
    }

    return _returnResponse(
      response,
      endPoint: endPoint,
      method: Method.PATCH,
      requestBody: requestBody,
    );
  }

  static Future<dynamic> apiDeleteRequest(String endPoint, Object body) async {
    dynamic response;
    final uri = _uri(endPoint);
    try {
      response = await client
          .delete(uri, body: jsonEncode(body), headers: AppHost.apiHeaders())
          .timeout(AppHost.requestTimeout);
    } on TimeoutException {
      throw FetchDataException(AppHost.timeoutMsg);
    } on SocketException {
      throw FetchDataException(AppHost.noInternetMsg);
    }

    return _returnResponse(
      response,
      endPoint: endPoint,
      method: Method.DELETE,
      requestBody: body,
    );
  }

  static void closeRequests() {
    client.close(); // 🚫 cancels all ongoing HTTP requests
    debugPrint("All ongoing HTTP requests have been canceled.");
  }

  /// Decodes the body once and, on failure, lifts DummyJSON's `message` into
  /// the thrown exception so the error view carries the server's own wording
  /// (e.g. "Product with id '999' not found").
  static dynamic _returnResponse(
    http.Response response, {
    required String endPoint,
    Method method = Method.GET,
    dynamic requestBody,
  }) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    // Local, not a static field: the product list and the category row fire
    // in parallel, and a shared field lets one request's error text land on
    // the other's exception.
    final message = (decoded is Map && decoded['message'] is String)
        ? decoded['message'] as String
        : AppHost.apiExceptionMsg;

    log('[$method] ${response.statusCode} $endPoint');

    switch (response.statusCode) {
      case 200:
      case 201:
        return decoded;
      case 204:
        throw NoContentException(message);
      case 400:
        throw BadRequestException(message);
      case 401:
        throw UnauthorisedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw ApiNotFoundException(message);
      case 409:
        throw ConflictException(message);
      case 422:
        throw UnprocessableEntityException(message);
      case 429:
        throw TooManyRequestsException(message);
      case 500:
      case 502:
        throw InternalServerException(message);
      case 503:
        throw ServiceUnavailableException(message);
      default:
        throw FetchDataException(message);
    }
  }
}

// ignore: constant_identifier_names
enum Method { GET, POST, PATCH, PUT, DELETE }
