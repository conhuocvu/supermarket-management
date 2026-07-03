class AppError {
  final String code;
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
  String toString() => 'AppError[$code]: $userMessage';
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
    throw Exception(error?.userMessage ?? 'Unknown application error');
  }
}
