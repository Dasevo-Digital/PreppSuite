import 'dart:async';
import 'dart:typed_data';

class InputTooLarge implements Exception {
  const InputTooLarge(this.limit);
  final int limit;
}

class OperationCancelled implements Exception {
  const OperationCancelled();
}

/// Listener removal matters: completed operations must not remain retained
/// by a screen's cancellation token, with all of their buffers alongside.
class CancellationToken {
  bool _cancelled = false;
  final _listeners = <void Function()>{};
  bool get cancelled => _cancelled;
  void check() {
    if (_cancelled) throw const OperationCancelled();
  }

  void Function() listen(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = _listeners.toList();
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }
}

/// Counts actual chunks even when Content-Length or a file size is wrong.
/// A deadline cancels the subscription; it does not leave a hidden reader
/// accumulating bytes after its caller stopped waiting.
Future<Uint8List> readBoundedBytes(
  Stream<List<int>> stream, {
  required int maxBytes,
  int? declaredLength,
  Duration? timeout,
  CancellationToken? cancellation,
  void Function()? onAbort,
}) {
  if (maxBytes < 0) throw ArgumentError.value(maxBytes, 'maxBytes');
  if (declaredLength != null && declaredLength > maxBytes) {
    onAbort?.call();
    return Future.error(InputTooLarge(maxBytes));
  }
  cancellation?.check();
  final result = Completer<Uint8List>();
  final bytes = BytesBuilder(copy: false);
  StreamSubscription<List<int>>? subscription;
  Timer? timer;
  void Function()? stopListening;
  void fail(Object error, [StackTrace? stack]) {
    if (result.isCompleted) return;
    bytes.clear();
    timer?.cancel();
    stopListening?.call();
    unawaited(subscription?.cancel());
    onAbort?.call();
    result.completeError(error, stack);
  }

  subscription = stream.listen(
    (chunk) {
      if (result.isCompleted) return;
      if (bytes.length + chunk.length > maxBytes) {
        fail(InputTooLarge(maxBytes));
      } else {
        bytes.add(chunk);
      }
    },
    onError: (Object error, StackTrace stack) => fail(error, stack),
    onDone: () {
      if (result.isCompleted) return;
      timer?.cancel();
      stopListening?.call();
      result.complete(bytes.takeBytes());
    },
  );
  if (result.isCompleted) {
    unawaited(subscription.cancel());
  }
  if (!result.isCompleted) {
    if (timeout != null) {
      timer = Timer(
        timeout,
        () => fail(TimeoutException('Input deadline', timeout)),
      );
    }
    stopListening = cancellation?.listen(
      () => fail(const OperationCancelled()),
    );
  }
  return result.future;
}
