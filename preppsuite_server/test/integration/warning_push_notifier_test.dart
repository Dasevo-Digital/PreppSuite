import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:preppsuite_server/src/notifications/services/push_sender.dart';
import 'package:preppsuite_server/src/notifications/warning_push_notifier.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Records what would have been sent, and can be told to reject a token so
/// the dead-token cleanup can be exercised without a live FCM project.
class _RecordingPushSender implements PushSender {
  _RecordingPushSender({this.deadTokens = const {}, this.configured = true});

  final Set<String> deadTokens;
  final bool configured;
  final sent = <({String token, String title})>[];

  @override
  bool get isConfigured => configured;

  @override
  Future<PushDeliveryStatus> send(
    Session session, {
    required PushDevice device,
    required PushMessage message,
  }) async {
    if (deadTokens.contains(device.token)) {
      return PushDeliveryStatus.tokenDead;
    }
    sent.add((token: device.token, title: message.title));
    return PushDeliveryStatus.delivered;
  }
}

void main() {
  withServerpod('Given WarningPushNotifier', (sessionBuilder, endpoints) {
    Future<TestSessionBuilder> userSession() async {
      final user = await const AuthUsers().create(sessionBuilder.build());
      return sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          user.id.toString(),
          {},
        ),
      );
    }

    Future<UuidValue> createHousehold({
      String countryCode = 'DE',
      String? regionKey,
      required String token,
    }) async {
      final session = await userSession();
      final household = await endpoints.household.createHousehold(
        session,
        name: 'Haushalt $token',
        countryCode: countryCode,
        regionKey: regionKey,
        displayName: 'Tester',
      );
      await endpoints.pushDevice.registerDevice(
        session,
        household.id!,
        token,
        PushPlatform.android,
      );
      return household.id!;
    }

    Future<Warning> insertWarning({
      required String externalId,
      String countryCode = 'DE',
      String? regionKey,
      WarningSeverity severity = WarningSeverity.severe,
      DateTime? expires,
    }) {
      return Warning.db.insertRow(
        sessionBuilder.build(),
        Warning(
          source: WarningSource.bbk,
          externalId: externalId,
          countryCode: countryCode,
          regionKey: regionKey,
          severity: severity,
          eventType: 'Unwetter',
          headline: 'Warnung $externalId',
          effective: DateTime.now().toUtc(),
          expires: expires,
          sent: DateTime.now().toUtc(),
          rawPayload: '{}',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    test(
      'when a warning is relevant then the household device is notified',
      () async {
        await createHousehold(token: 'token-1');
        final warning = await insertWarning(externalId: 'w1');
        final sender = _RecordingPushSender();

        final count = await WarningPushNotifier(
          sender: sender,
        ).notify(sessionBuilder.build(), [warning]);

        expect(count, 1);
        expect(sender.sent.single.token, 'token-1');
        expect(sender.sent.single.title, 'Warnung w1');
      },
    );

    test(
      'when the warning is for another country then nobody is notified',
      () async {
        await createHousehold(token: 'token-1');
        final warning = await insertWarning(
          externalId: 'w1',
          countryCode: 'AT',
        );
        final sender = _RecordingPushSender();

        await WarningPushNotifier(
          sender: sender,
        ).notify(sessionBuilder.build(), [warning]);

        expect(sender.sent, isEmpty);
      },
    );

    test(
      'when the warning is for another region then nobody is notified',
      () async {
        // Same relevance rule the pull uses — a Kreis-scoped warning must not
        // wake a household two states over.
        await createHousehold(token: 'token-1', regionKey: '05315000');
        final warning = await insertWarning(
          externalId: 'w1',
          regionKey: '09162',
        );
        final sender = _RecordingPushSender();

        await WarningPushNotifier(
          sender: sender,
        ).notify(sessionBuilder.build(), [warning]);

        expect(sender.sent, isEmpty);
      },
    );

    test('when a warning is only minor then it is not pushed', () async {
      // The floor exists so the channel keeps meaning something; a phone
      // that buzzes for every minor advisory gets muted.
      await createHousehold(token: 'token-1');
      final warning = await insertWarning(
        externalId: 'w1',
        severity: WarningSeverity.minor,
      );
      final sender = _RecordingPushSender();

      await WarningPushNotifier(
        sender: sender,
      ).notify(sessionBuilder.build(), [warning]);

      expect(sender.sent, isEmpty);
    });

    test('when a warning has already expired then it is not pushed', () async {
      await createHousehold(token: 'token-1');
      final warning = await insertWarning(
        externalId: 'w1',
        expires: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      );
      final sender = _RecordingPushSender();

      await WarningPushNotifier(
        sender: sender,
      ).notify(sessionBuilder.build(), [warning]);

      expect(sender.sent, isEmpty);
    });

    test('when there are no credentials then nothing is attempted', () async {
      await createHousehold(token: 'token-1');
      final warning = await insertWarning(externalId: 'w1');
      final sender = _RecordingPushSender(configured: false);

      final count = await WarningPushNotifier(
        sender: sender,
      ).notify(sessionBuilder.build(), [warning]);

      expect(count, 0);
      expect(sender.sent, isEmpty);
    });

    test('when the same warning comes in twice then it is sent once', () async {
      // A BBK warning is found by both the nationwide poll and the
      // per-Kreis one in the same run.
      await createHousehold(token: 'token-1');
      final warning = await insertWarning(externalId: 'w1');
      final sender = _RecordingPushSender();

      await WarningPushNotifier(
        sender: sender,
      ).notify(sessionBuilder.build(), [warning, warning]);

      expect(sender.sent, hasLength(1));
    });

    test(
      'when many warnings arrive at once then the device is capped',
      () async {
        // The cold-start case: the first poll of an empty database inserts
        // every active warning in the country, and all of them count as new.
        await createHousehold(token: 'token-1');
        final warnings = [
          for (var i = 0; i < 10; i++) await insertWarning(externalId: 'w$i'),
        ];
        final sender = _RecordingPushSender();

        await WarningPushNotifier(
          sender: sender,
        ).notify(sessionBuilder.build(), warnings);

        expect(sender.sent, hasLength(WarningPushNotifier.maxPerDevicePerRun));
      },
    );

    test(
      'when the cap bites then the most severe warnings get through',
      () async {
        await createHousehold(token: 'token-1');
        final warnings = [
          for (var i = 0; i < 5; i++)
            await insertWarning(
              externalId: 'moderate-$i',
              severity: WarningSeverity.moderate,
            ),
          await insertWarning(
            externalId: 'extreme',
            severity: WarningSeverity.extreme,
          ),
        ];
        final sender = _RecordingPushSender();

        await WarningPushNotifier(
          sender: sender,
        ).notify(sessionBuilder.build(), warnings);

        expect(
          sender.sent.map((s) => s.title),
          contains('Warnung extreme'),
        );
      },
    );

    test(
      'when the push service rejects a token then the device is removed',
      () async {
        await createHousehold(token: 'stale-token');
        final warning = await insertWarning(externalId: 'w1');
        final sender = _RecordingPushSender(deadTokens: {'stale-token'});

        await WarningPushNotifier(
          sender: sender,
        ).notify(sessionBuilder.build(), [warning]);

        expect(await PushDevice.db.find(sessionBuilder.build()), isEmpty);
      },
    );

    test('when a token merely fails then the device is kept', () async {
      // A network blip must not unsubscribe anyone.
      final failing = _AlwaysFailingSender();
      await createHousehold(token: 'token-1');
      final warning = await insertWarning(externalId: 'w1');

      await WarningPushNotifier(
        sender: failing,
      ).notify(sessionBuilder.build(), [warning]);

      expect(await PushDevice.db.find(sessionBuilder.build()), hasLength(1));
    });
  });
}

class _AlwaysFailingSender implements PushSender {
  @override
  bool get isConfigured => true;

  @override
  Future<PushDeliveryStatus> send(
    Session session, {
    required PushDevice device,
    required PushMessage message,
  }) async => PushDeliveryStatus.failed;
}
