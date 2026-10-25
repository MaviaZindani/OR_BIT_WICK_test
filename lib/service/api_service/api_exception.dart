class ApiExceptions implements Exception {
  final String? _message;
  final int? errorCode; // Optional error code

  ApiExceptions([this._message, this.errorCode]);

  @override
  String toString() {
    return "${errorCode != null ? '[$errorCode] ' : ''}$_message";
  }
}

// Specific Exception Classes with Shorter Messages
class FetchDataException extends ApiExceptions {
  FetchDataException([String? message])
    : super(message ?? "Connection failed. Try again later.");
}

class BadRequestException extends ApiExceptions {
  BadRequestException([String? message])
    : super(message ?? "Invalid request. Check input and try again.");
}

class UnauthorisedException extends ApiExceptions {
  UnauthorisedException([String? message])
    : super(message ?? "Unauthorized. Please log in again.");
}

class ApiNotFoundException extends ApiExceptions {
  ApiNotFoundException([String? message])
    : super(message ?? "Resource not found.");
}

class InvalidInputException extends ApiExceptions {
  InvalidInputException([String? message])
    : super(message ?? "Invalid input. Check and try again.");
}

class UnprocessableEntityException extends ApiExceptions {
  UnprocessableEntityException([String? message])
    : super(message ?? "Server can't process the request.");
}

class NoContentException extends ApiExceptions {
  NoContentException([String? message])
    : super(message ?? "Request successful, but no content.");
}

class ForbiddenException extends ApiExceptions {
  ForbiddenException([String? message])
    : super(message ?? "Permission denied.");
}

class ConflictException extends ApiExceptions {
  ConflictException([String? message])
    : super(message ?? "Conflict occurred. Try again later.");
}

class TooManyRequestsException extends ApiExceptions {
  TooManyRequestsException([String? message])
    : super(message ?? "Too many requests. Slow down and try again.");
}

class InternalServerException extends ApiExceptions {
  InternalServerException([String? message])
    : super(message ?? "Server error. Try again later.");
}

class ServiceUnavailableException extends ApiExceptions {
  ServiceUnavailableException([String? message])
    : super(message ?? "Service unavailable. Try again later.");
}
