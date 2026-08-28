import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:preppsuite_server/src/notifications/services/fcm_sender.dart';
import 'package:preppsuite_server/src/notifications/services/push_sender.dart';
import 'package:test/test.dart';

void main() {
  PushDevice device(PushPlatform platform) => PushDevice(
    householdId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
    authUserId: UuidValue.fromString('00000000-0000-4000-8000-000000000002'),
    token: 'token-abc',
    platform: platform,
    updatedAt: DateTime.utc(2026),
    createdAt: DateTime.utc(2026),
  );

  const message = PushMessage(
    title: 'Hochwasser',
    body: 'Unwetterwarnung',
    data: {'type': 'warning'},
  );

  group('buildFcmMessage', () {
    test('addresses the device by its token', () {
      final built = buildFcmMessage(
        device: device(PushPlatform.android),
        message: message,
      );

      expect(built['token'], 'token-abc');
      expect(built['notification'], {
        'title': 'Hochwasser',
        'body': 'Unwetterwarnung',
      });
      expect(built['data'], {'type': 'warning'});
    });

    test('names the notification channel Android needs', () {
      // Android 8+ drops a notification whose channel it does not know,
      // without an error anywhere — and the channel has to be the one the
      // app itself created.
      final built = buildFcmMessage(
        device: device(PushPlatform.android),
        message: message,
      );

      final android = built['android'] as Map<String, dynamic>;
      expect(android['priority'], 'HIGH');
      expect(
        (android['notification'] as Map<String, dynamic>)['channel_id'],
        'warnings',
      );
      expect(built.containsKey('apns'), isFalse);
    });

    test('spells the alert out under aps for iOS', () {
      // APNs shows nothing it cannot find in `aps`; the top-level
      // `notification` block alone reaches Android only.
      final built = buildFcmMessage(
        device: device(PushPlatform.ios),
        message: message,
      );

      final apns = built['apns'] as Map<String, dynamic>;
      expect((apns['headers'] as Map)['apns-priority'], '10');
      final aps = ((apns['payload'] as Map)['aps'] as Map)['alert'] as Map;
      expect(aps['title'], 'Hochwasser');
      expect(aps['body'], 'Unwetterwarnung');
      expect(built.containsKey('android'), isFalse);
    });

    test('omits an empty data block rather than sending an empty map', () {
      final built = buildFcmMessage(
        device: device(PushPlatform.android),
        message: const PushMessage(title: 'a', body: 'b'),
      );

      expect(built.containsKey('data'), isFalse);
    });
  });

  group('isDeadTokenResponse', () {
    test('an unregistered token is dead', () {
      expect(
        isDeadTokenResponse(404, '{"error":{"status":"UNREGISTERED"}}'),
        isTrue,
      );
    });

    test('a malformed token is dead', () {
      expect(
        isDeadTokenResponse(400, '{"error":{"status":"INVALID_ARGUMENT"}}'),
        isTrue,
      );
    });

    test('a quota rejection is not', () {
      // Transient. Deleting the device here would unsubscribe people for
      // the sole reason that the server was busy.
      expect(
        isDeadTokenResponse(429, '{"error":{"status":"RESOURCE_EXHAUSTED"}}'),
        isFalse,
      );
    });

    test('a server error is not', () {
      expect(
        isDeadTokenResponse(503, '{"error":{"status":"UNAVAILABLE"}}'),
        isFalse,
      );
    });

    test('a 403 from a bad credential is not', () {
      // The token is fine; the *server* is misconfigured. Wiping every
      // device because a service-account key expired would be the worst
      // possible response.
      expect(
        isDeadTokenResponse(403, '{"error":{"status":"PERMISSION_DENIED"}}'),
        isFalse,
      );
    });

    test('an unparseable body is not treated as dead', () {
      expect(isDeadTokenResponse(404, '<html>not json</html>'), isFalse);
    });
  });

  group('fromServiceAccountJson', () {
    test('no credentials means no sender, not a crash', () {
      // The normal state of a fresh self-hosted install: the server has to
      // boot and poll warnings with push simply switched off.
      expect(FcmSender.fromServiceAccountJson(null), isNull);
      expect(FcmSender.fromServiceAccountJson('   '), isNull);
    });

    test('unparseable or incomplete credentials mean no sender', () {
      expect(FcmSender.fromServiceAccountJson('not json'), isNull);
      expect(
        FcmSender.fromServiceAccountJson('{"type":"service_account"}'),
        isNull,
      );
    });
  });
}
