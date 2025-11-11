import 'dart:math';

typedef ShouldRetry = bool Function(Object error, int attempt);

Future<T> retry<T>(
  Future<T> Function() task, {
  required ShouldRetry shouldRetry,
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 300),
  Duration maxDelay = const Duration(seconds: 2),
}) async {
  int attempt = 0;
  Object? lastError;

  while (attempt < maxAttempts) {
    try {
      return await task();
    } catch (e) {
      lastError = e;
      attempt++;
      if (attempt >= maxAttempts || !shouldRetry(e, attempt)) rethrow;

      final jitter = Random().nextDouble() + 0.5; // 0.5–1.5x
      final backoffMs =
          (baseDelay.inMilliseconds * (1 << (attempt - 1)) * jitter)
              .clamp(baseDelay.inMilliseconds, maxDelay.inMilliseconds)
              .toInt();
      await Future.delayed(Duration(milliseconds: backoffMs));
    }
  }
  // ignore: only_throw_errors
  throw lastError!;
}
