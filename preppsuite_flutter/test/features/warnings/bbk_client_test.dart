import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';

/// Counts how many requests are in flight at once.
///
/// Six sources asked one after another meant six round trips to the same
/// host before the warning list could be drawn. On a desk connection that
/// was 115 ms against 28; on mobile data at 200 ms a round trip it is a
/// second and a quarter in front of the screen somebody opens first in an
/// emergency.
class _CountingClient extends http.BaseClient {
  _CountingClient({this.failing = const {}});

  /// Sources to answer with a 500.
  final Set<String> failing;

  var inFlight = 0;
  var mostAtOnce = 0;
  final asked = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final source =
        request.url.pathSegments[request.url.pathSegments.length - 2];
    asked.add(source);

    inFlight++;
    if (inFlight > mostAtOnce) mostAtOnce = inFlight;

    // A real pause, so overlapping is measured rather than inferred from
    // how fast a fake answered. Deliberately not a gate that waits for
    // all six: against the old sequential code that would deadlock, and a
    // test that hangs instead of failing says nothing.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    inFlight--;

    if (failing.contains(source)) {
      return http.StreamedResponse(const Stream.empty(), 500);
    }
    return http.StreamedResponse(
      Stream<List<int>>.value('[]'.codeUnits),
      200,
    );
  }
}

void main() {
  test('all six sources are asked at once, not one after another', () async {
    final client = _CountingClient();
    final result = await BbkClient(httpClient: client).fetchAll();

    expect(client.asked.length, 6);
    expect(
      client.mostAtOnce,
      6,
      reason: 'six round trips in a row is what this replaced',
    );
    expect(result.complete, isTrue);
    expect(result.warnings, isEmpty);
  });

  test('one source failing still leaves the others, and says so', () async {
    // The flag is what makes expiring stale warnings safe: a failed fetch
    // must never read as "nothing is warned about right now".
    final client = _CountingClient(failing: {'lhp'});
    final result = await BbkClient(httpClient: client).fetchAll();

    expect(client.asked.length, 6);
    expect(result.complete, isFalse);
  });

  test('every published source is asked', () async {
    final client = _CountingClient();
    await BbkClient(httpClient: client).fetchAll();

    expect(client.asked.toSet(), {
      'mowas',
      'dwd',
      'katwarn',
      'biwapp',
      'lhp',
      'police',
    });
  });
}
