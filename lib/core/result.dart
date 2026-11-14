class AppError {
  const AppError({
    required this.code,
    required this.message,
    this.fields = const {},
  });

  final String code;
  final String message;
  final Map<String, String> fields;
}

class AppResult<T> {
  const AppResult._({this.value, this.error});

  factory AppResult.ok(T value) => AppResult._(value: value);

  factory AppResult.fail(AppError error) => AppResult._(error: error);

  final T? value;
  final AppError? error;

  bool get isOk => error == null;
}
