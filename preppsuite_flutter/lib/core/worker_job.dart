import 'dart:async';
import 'dart:isolate';

import 'bounded_input.dart';

/// CPU work gets a killable isolate, rather than a Future.timeout around
/// work that would continue using memory and CPU after the UI gave up.
Future<R> runInWorker<A, R>(
  A input,
  FutureOr<R> Function(A) action, {
  CancellationToken? cancellation,
  Duration timeout = const Duration(seconds: 60),
}) async {
  cancellation?.check();
  final port = ReceivePort();
  final result = Completer<R>();
  Isolate? isolate;
  void stop(Object error, [StackTrace? stack]) {
    if (result.isCompleted) return;
    isolate?.kill(priority: Isolate.immediate);
    result.completeError(error, stack);
  }

  final timer = Timer(
    timeout,
    () => stop(TimeoutException('Worker deadline', timeout)),
  );
  final remove = cancellation?.listen(() => stop(const OperationCancelled()));
  final messages = port.listen((message) {
    if (result.isCompleted) return;
    if (message case (true, final R value)) {
      result.complete(value);
    } else if (message case (
      false,
      final Object error,
      final StackTrace stack,
    )) {
      stop(error, stack);
    } else if (message case [final String error, final String stack]) {
      stop(StateError(error), StackTrace.fromString(stack));
    } else if (message == null) {
      stop(StateError('Worker exited without a result'));
    }
  });
  try {
    // A static entry point avoids capturing this method's ports/completer.
    final spawning = Isolate.spawn(
      (_run<A, R>),
      (port.sendPort, input, action),
      onError: port.sendPort,
      onExit: port.sendPort,
      errorsAreFatal: true,
    );
    // Register an error listener before an immediately cancelled operation.
    final running = () async {
      isolate = await spawning;
      if (result.isCompleted) isolate?.kill(priority: Isolate.immediate);
    }();
    await Future.wait([running, result.future], eagerError: true);
    return await result.future;
  } finally {
    timer.cancel();
    remove?.call();
    isolate?.kill(priority: Isolate.immediate);
    await messages.cancel();
    port.close();
  }
}

void _run<A, R>((SendPort, A, FutureOr<R> Function(A)) request) async {
  final (reply, input, action) = request;
  try {
    reply.send((true, await action(input)));
  } catch (error, stack) {
    reply.send((false, error, stack));
  }
}
