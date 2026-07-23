import '../errors/failure.dart';

/// A minimal `Either`-style result type used as the return contract for
/// every repository method in the domain layer. Avoids throwing exceptions
/// across architectural boundaries and forces call sites to explicitly
/// handle the failure path.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  /// Returns the success value or `null` if this is a failure.
  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        ResultFailure<T>() => null,
      };

  /// Returns the failure or `null` if this is a success.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        ResultFailure<T>(failure: final f) => f,
      };

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => success(d),
      ResultFailure<T>(failure: final f) => failure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
