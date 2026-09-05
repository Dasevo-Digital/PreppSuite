import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart' as proto;

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';
import 'warning_region_filter.dart';

export '../../../core/app_database_providers.dart';

/// Not-yet-expired warnings — drives the app-wide banner.
final activeWarningsProvider = StreamProvider.autoDispose<List<Warning>>(
  (ref) => ref.watch(appDatabaseProvider).watchActiveWarnings(),
);

/// Full history, including expired warnings — the dedicated warnings screen.
final allWarningsProvider = StreamProvider.autoDispose<List<Warning>>(
  (ref) => ref.watch(appDatabaseProvider).watchAllWarnings(),
);

/// Converts the server-shaped household and its extra region subscriptions
/// into the plain filter the relevance rules and the background worker
/// use.
///
/// The one place that still touches the generated client types for
/// warnings — everything downstream is free of them, which is what lets the
/// background isolate reuse the same rules.
WarningRegionFilter warningRegionFilterFor(
  proto.Household household,
  List<proto.WarningRegionSubscription> subscriptions,
) {
  return WarningRegionFilter(
    countryCode: household.countryCode,
    ownRegionKey: household.regionKey,
    extraRegions: [
      for (final subscription in subscriptions)
        WarningRegion(
          kind: switch (subscription.kind) {
            proto.WarningRegionKind.kreis => WarningRegionKind.kreis,
            proto.WarningRegionKind.bundesland => WarningRegionKind.bundesland,
          },
          value: subscription.value,
        ),
    ],
  );
}
