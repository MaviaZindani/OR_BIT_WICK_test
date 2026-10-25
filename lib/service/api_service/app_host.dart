class AppHost {
  static const String apiExceptionMsg = "Try Again Later.";
  static const String apiBadResponseMsg =
      'Unexpected response from the server.';
  static const String noInternetMsg =
      'No Internet Connection. Connect Your Internet & Try Again.';
  static const String timeoutMsg = 'The server took too long to respond.';

  static const int apiSuccessCode = 200;

  /// How long a single request may hang before it is reported as a timeout
  /// rather than leaving a spinner on screen indefinitely.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// DummyJSON is a keyless public api, so there is nothing to attach here.
  /// Kept as the single place an `Authorization` header would go.
  static Map<String, String> apiHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  static Map<String, String> apiQueryParams() {
    return {};
  }
}
