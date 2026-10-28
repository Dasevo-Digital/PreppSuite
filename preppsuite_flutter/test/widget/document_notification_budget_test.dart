import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:preppsuite_flutter/core/notifications_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/expiry_reminder_scheduler.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'document reminders share the 60-slot budget, protect private labels and cancel on opt-out',
    (tester) async {
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
      final now = DateTime.now();
      const store = PersonalDocumentStore();
      for (var i = 0; i < 15; i++) {
        final d = (await store.add(
          location: '/private/$i.md',
          label: 'Privates Dokument $i',
        )).last;
        await store.updateDeadline(
          d.id,
          validUntil: null,
          remindOn: DateTime(now.year, now.month, now.day + 5),
          reviewedOn: null,
          originalLocation: 'Privatablage',
        );
      }
      final items = <InventoryItem>[
        for (var i = 0; i < 80; i++)
          InventoryItem(
            clientId: 'food-$i',
            householdId: 'home',
            name: 'Food $i',
            category: 'food',
            quantity: 1,
            unit: 'g',
            storageLocation: 'A',
            updatedAt: now,
            dirty: false,
            expirationDate: DateTime(now.year, now.month, now.day + 45),
          ),
        for (var i = 0; i < 5; i++)
          InventoryItem(
            clientId: 'medicine-$i',
            householdId: 'home',
            name: 'Medicine $i',
            category: 'medical',
            quantity: 60,
            unit: 'tablets',
            storageLocation: 'A',
            updatedAt: now,
            dirty: false,
            dailyDose: 2,
            refillLeadDays: 7,
            stockCountedAt: now,
          ),
        for (var i = 0; i < 5; i++)
          InventoryItem(
            clientId: 'device-$i',
            householdId: 'home',
            name: 'Radio $i',
            category: 'tools',
            quantity: 1,
            unit: 'piece',
            storageLocation: 'A',
            updatedAt: now,
            dirty: false,
            chargeEveryDays: 14,
            chargeCheckedAt: now,
          ),
      ];
      final pending = <int, Map<String, dynamic>>{
        for (var i = 0; i < 60; i++)
          -i - 1: {
            'id': -i - 1,
            'title': 'Previous',
            'body': 'Previous',
            'payload': 'expiry:previous-$i',
          },
        for (final id in [90407, 90408, 90409])
          id: {
            'id': id,
            'title': 'Other',
            'body': 'Other',
            'payload': 'reserved',
          },
      };
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'initialize':
            return true;
          case 'pendingNotificationRequests':
            return pending.values.toList();
          case 'zonedSchedule':
            final a = Map<String, dynamic>.from(call.arguments as Map);
            pending[a['id'] as int] = a;
            expect(
              pending.length,
              lessThanOrEqualTo(64),
              reason: 'rescheduling must never exceed the OS limit',
            );
            return null;
          case 'cancel':
            pending.remove((call.arguments as Map)['id']);
            return null;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemsProvider('home')
                .overrideWith((_) => Stream.value(items)),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: ExpiryReminderScheduler(householdId: 'home'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      int count(String prefix) => pending.values
          .where((v) => (v['payload'] as String? ?? '').startsWith(prefix))
          .length;
      expect(count('refill:'), 5);
      expect(count('charge-item:'), 5);
      expect(count('document-deadline:'), 15);
      expect(count('expiry:'), 35);
      expect(pending, hasLength(63));
      for (final value in pending.values.where(
        (v) => (v['payload'] as String).startsWith('document-deadline:'),
      )) {
        expect(value['body'], isNot(contains('Privat')));
        expect(value['title'], 'Dokumentenfrist');
      }
      final context = tester.element(find.byType(ExpiryReminderScheduler));
      await ProviderScope.containerOf(context)
          .read(notificationsEnabledProvider.notifier)
          .setEnabled(false);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(pending.keys, unorderedEquals([90407, 90408, 90409]));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
