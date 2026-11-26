import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/features/sharing/application/sharing_providers.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/features/sharing/presentation/folder_encryption_section.dart';
import 'package:preppsuite_flutter/features/sharing/presentation/shared_folder_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

/// A controller that only reports a run that has already happened.
class _Reported extends SharedFolderController {
  _Reported(this.result);

  final SharedFolderSyncResult result;

  @override
  Future<SharedFolderState> build() async => SharedFolderState(
    folder: const PickedStorage(value: '/nirgends', label: 'Ordner'),
    lastResult: result,
  );
}

/// What the sharing card says about the last run.
void main() {
  const profile = HouseholdProfile(
    id: 'home',
    name: 'Familie',
    countryCode: 'DE',
  );

  Future<void> show(WidgetTester tester, SharedFolderSyncResult result) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedFolderProvider.overrideWith(() => _Reported(result)),
          folderEncryptedProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: SingleChildScrollView(
                child: SharedFolderCard(
                  profile: profile,
                  l10n: AppLocalizations.of(context)!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // A row from an older version that cannot travel stopped every publish,
  // and the card said only that the next attempt runs on its own (#397).
  testWidgets(
    'a row that cannot travel is named, and retrying is not promised',
    (
      tester,
    ) async {
      await show(
        tester,
        const SharedFolderSyncResult(
          error: SharedFolderSyncError.invalidRows,
          cause: InventoryNeedsCorrection(['Reis']),
        ),
      );

      expect(find.textContaining('Reis'), findsOneWidget);
      expect(find.textContaining('nicht in den Ordner'), findsOneWidget);
      expect(find.textContaining('läuft von allein'), findsNothing);
    },
  );
}
