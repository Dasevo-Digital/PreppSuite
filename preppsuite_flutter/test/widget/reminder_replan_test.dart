import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/expiry_reminder_scheduler.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A change to the inventory that changes no reminder schedules nothing
/// (#252).
void main() {
  testWidgets('only a changed plan is scheduled again', (tester) async {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    final now = DateTime.now();

    InventoryItem item(int i, {String notes = '', int expiresInDays = 45}) =>
        InventoryItem(
          clientId: 'food-$i',
          householdId: 'home',
          name: 'Food $i',
          category: 'food',
          quantity: 1,
          unit: 'g',
          storageLocation: 'A',
          notes: notes,
          updatedAt: now,
          dirty: false,
          expirationDate: DateTime(
            now.year,
            now.month,
            now.day + expiresInDays,
          ),
        );

    final pending = <int, Map<String, dynamic>>{};
    var platformCalls = 0;
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'pendingNotificationRequests':
          platformCalls++;
          return pending.values.toList();
        case 'zonedSchedule':
          platformCalls++;
          final arguments = Map<String, dynamic>.from(call.arguments as Map);
          pending[arguments['id'] as int] = arguments;
          return null;
        case 'cancel':
          platformCalls++;
          pending.remove((call.arguments as Map)['id']);
          return null;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final inventory = StreamController<List<InventoryItem>>.broadcast();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider('home').overrideWith((_) => inventory.stream),
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

    Future<void> emit(List<InventoryItem> items) async {
      inventory.add(items);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    }

    await emit([for (var i = 0; i < 5; i++) item(i)]);
    expect(pending, hasLength(10), reason: 'five items, 30 and 7 days ahead');

    // A note on one item: nothing any reminder says or when.
    platformCalls = 0;
    await emit([
      for (var i = 0; i < 5; i++) item(i, notes: i == 2 ? 'Keller' : ''),
    ]);
    expect(platformCalls, 0);

    // A new date on one item is a new plan.
    await emit([
      for (var i = 0; i < 5; i++) item(i, expiresInDays: i == 2 ? 60 : 45),
    ]);
    expect(platformCalls, greaterThan(0));
    expect(pending, hasLength(10));
    final fireDates = {
      for (final value in pending.values)
        DateTime.parse(value['scheduledDateTimeISO8601'] as String),
    };
    expect(fireDates, hasLength(4), reason: 'item 2 now fires on two new days');

    await tester.pumpWidget(const SizedBox.shrink());
    await inventory.close();
  });
}
