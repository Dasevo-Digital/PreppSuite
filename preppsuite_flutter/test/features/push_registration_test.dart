import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show PushPlatform;
import 'package:preppsuite_flutter/core/push_registration.dart';
import 'package:preppsuite_flutter/core/push_token_source.dart';

class _FakeTokenSource implements PushTokenSource {
  _FakeTokenSource({this.available = true, this.value = 'token-1'});

  final bool available;
  String? value;
  final _refreshes = StreamController<String>.broadcast();

  @override
  bool get isAvailable => available;

  @override
  Future<String?> token() async => value;

  @override
  Stream<String> get onTokenRefresh => _refreshes.stream;
}

class _MemoryTokenStore implements RegisteredTokenStore {
  _MemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String? token) async => _token = token;
}

void main() {
  late List<({String householdId, String token, PushPlatform platform})>
  registered;
  late List<String> unregistered;
  late bool unregisterFails;

  setUp(() {
    registered = [];
    unregistered = [];
    unregisterFails = false;
  });

  PushRegistrationService service({
    PushTokenSource? tokenSource,
    RegisteredTokenStore? store,
  }) {
    return PushRegistrationService(
      tokenSource: tokenSource ?? _FakeTokenSource(),
      store: store ?? _MemoryTokenStore(),
      register: (householdId, token, platform) async => registered.add((
        householdId: householdId,
        token: token,
        platform: platform,
      )),
      unregister: (token) async {
        if (unregisterFails) throw StateError('offline');
        unregistered.add(token);
      },
    );
  }

  /// The registration path only runs on a platform that has a push
  /// service, and these tests run on the host. Where that matters the
  /// assertion is split rather than skipped, so the desktop case is
  /// checked too instead of silently passing.
  final onPushPlatform = currentPushPlatform() != null;

  group('reconcile with notifications on', () {
    test('registers the current token', () async {
      final result = await service().reconcile(
        enabled: true,
        householdId: 'h1',
      );

      if (onPushPlatform) {
        expect(result, 'token-1');
        expect(registered.single.householdId, 'h1');
        expect(registered.single.token, 'token-1');
      } else {
        expect(result, isNull);
        expect(registered, isEmpty);
      }
    });

    test('does nothing when push is not available in this build', () async {
      // The state of the app until a Firebase project is configured.
      final result = await service(
        tokenSource: _FakeTokenSource(available: false),
      ).reconcile(enabled: true, householdId: 'h1');

      expect(result, isNull);
      expect(registered, isEmpty);
      expect(unregistered, isEmpty);
    });

    test('does nothing when no token can be obtained', () async {
      final result = await service(
        tokenSource: _FakeTokenSource(value: null),
      ).reconcile(enabled: true, householdId: 'h1');

      expect(result, isNull);
      expect(registered, isEmpty);
    });
  });

  group('reconcile with notifications off', () {
    test('revokes a previously registered token', () async {
      final store = _MemoryTokenStore('old-token');

      final result = await service(
        store: store,
      ).reconcile(enabled: false, householdId: 'h1');

      expect(result, isNull);
      expect(unregistered, ['old-token']);
      expect(await store.read(), isNull);
    });

    test('does nothing when nothing was ever registered', () async {
      await service().reconcile(enabled: false, householdId: 'h1');

      expect(unregistered, isEmpty);
    });

    test('keeps the token when the server could not be reached', () async {
      // The point of keeping it is the retry on next launch. Clearing it
      // here would leave the server pushing to this device forever, with
      // nothing left on the device that knows which token to revoke.
      unregisterFails = true;
      final store = _MemoryTokenStore('old-token');

      await service(store: store).reconcile(enabled: false, householdId: 'h1');

      expect(await store.read(), 'old-token');
    });
  });

  test('signing out revokes even without a household', () async {
    final store = _MemoryTokenStore('old-token');

    await service(store: store).reconcile(enabled: true, householdId: null);

    expect(unregistered, ['old-token']);
    expect(registered, isEmpty);
  });

  test('a rotated token replaces the old registration', () async {
    // FCM keeps delivering to a rotated token for a while; leaving it
    // registered means the same warning arrives twice.
    final store = _MemoryTokenStore('old-token');
    await service(
      tokenSource: _FakeTokenSource(value: 'new-token'),
      store: store,
    ).reconcile(enabled: true, householdId: 'h1');

    if (!onPushPlatform) return;
    expect(unregistered, ['old-token']);
    expect(registered.single.token, 'new-token');
    expect(await store.read(), 'new-token');
  });

  test('re-registering the same token does not revoke it first', () async {
    final store = _MemoryTokenStore('token-1');
    await service(store: store).reconcile(enabled: true, householdId: 'h1');

    if (!onPushPlatform) return;
    expect(unregistered, isEmpty);
    expect(registered.single.token, 'token-1');
  });
}
