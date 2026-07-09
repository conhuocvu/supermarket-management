enum ErrorCode {
  VALIDATION,
  AUTHENTICATION_REQUIRED,
  PERMISSION_DENIED,
  NOT_FOUND,
  CONFLICT,
  RATE_LIMITED,
  NETWORK,
  TIMEOUT,
  SERVICE_UNAVAILABLE,
  DATA_INTEGRITY,
  CANCELLED,
  INTERNAL,
}

class AppError {
  final ErrorCode code;
  final String userMessage;
  final bool retryable;
  final String correlationId;
  final Map<String, String>? fieldErrors;

  AppError({
    required this.code,
    required this.userMessage,
    this.retryable = false,
    this.correlationId = '',
    this.fieldErrors,
  });

  @override
  String toString() => 'AppError[${code.name}]: $userMessage';
}

class Result<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;

  Result.success(this.data)
      : error = null,
        isSuccess = true;

  Result.failure(this.error)
      : data = null,
        isSuccess = false;

  T get dataOrThrow {
    if (isSuccess) return data!;
    throw error!;
  }
}
