import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../knowledge/application/knowledge_index_database.dart';
import '../../knowledge/application/personal_document_index.dart';

/// Build and schema versions that help identify a device's local state.
///
/// Schema constants are read without opening any database.  Opening one from
/// Settings merely to display a number could create a database on a new app
/// install, which is both surprising and unnecessary.
class VersionInfoCard extends StatelessWidget {
  const VersionInfoCard({super.key, this.packageInfo});

  /// Kept injectable for widget tests and for platforms where the native
  /// package-information plugin is not available yet.
  final Future<PackageInfo>? packageInfo;

  Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await (packageInfo ?? PackageInfo.fromPlatform());
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Column(
        children: [
          FutureBuilder<PackageInfo?>(
            future: _loadPackageInfo(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final value = info == null
                  ? l10n.settingsVersionInfoUnavailable
                  : l10n.settingsVersionInfoAppValue(
                      info.version,
                      info.buildNumber,
                    );
              return _VersionRow(
                icon: Icons.info_outline,
                label: l10n.settingsVersionInfoApp,
                value: value,
              );
            },
          ),
          const Divider(height: 1),
          _VersionRow(
            icon: Icons.storage_outlined,
            label: l10n.settingsVersionInfoDatabase,
            value: l10n.settingsVersionInfoSchema(
              AppDatabase.currentSchemaVersion,
            ),
          ),
          const Divider(height: 1),
          _VersionRow(
            icon: Icons.menu_book_outlined,
            label: l10n.settingsVersionInfoKnowledgeIndex,
            value: l10n.settingsVersionInfoSchema(
              KnowledgeIndexDatabase.currentSchemaVersion,
            ),
          ),
          const Divider(height: 1),
          _VersionRow(
            icon: Icons.description_outlined,
            label: l10n.settingsVersionInfoDocumentsIndex,
            value: l10n.settingsVersionInfoSchema(
              PersonalDocumentIndex.currentSchemaVersion,
            ),
          ),
          const Divider(height: 1),
          _VersionRow(
            icon: Icons.map_outlined,
            label: l10n.settingsVersionInfoOfflineMap,
            value: l10n.settingsVersionInfoPmtiles,
          ),
          const Divider(height: 1),
          _VersionRow(
            icon: Icons.medical_information_outlined,
            label: l10n.settingsVersionInfoFirstAid,
            value: l10n.settingsVersionInfoFirstAidValue,
          ),
        ],
      ),
    );
  }
}

/// A name and its value, side by side where both fit and stacked where
/// they do not.
///
/// A `ListTile` cannot do this. It hands `trailing` the full width that
/// widget asks for and squeezes the title into whatever is left, so on a
/// phone „Erste-Hilfe-Inhalte" beside „Quellenstand ERC 2025
/// (GRC-Fassung)" came out as five lines, broken at every hyphen:
/// „Erste" / „-" / „Hilfe-" / „Inhal" / „te". Nothing overflowed and no
/// test failed; it just looked broken, on the one screen someone opens
/// to read a version number out loud.
///
/// Whether the two fit is a question about *these words at this size*,
/// not about the screen class, so it is measured rather than guessed at
/// a breakpoint. That also holds for a translation, and for someone who
/// has turned the system font up.
class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const _padding = 16.0;
  static const _iconSize = 24.0;

  /// Between the name and its value, so the two never read as one phrase.
  static const _gap = 16.0;

  static double _widthOf(
    String text,
    TextStyle? style,
    TextScaler scaler,
    TextDirection direction,
  ) => (TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: direction,
    textScaler: scaler,
    maxLines: 1,
  )..layout()).width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyLarge;
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _padding,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: _iconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: _padding),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final needed =
                      _widthOf(label, labelStyle, scaler, direction) +
                      _gap +
                      _widthOf(value, valueStyle, scaler, direction);
                  if (needed <= constraints.maxWidth) {
                    return Row(
                      children: [
                        Expanded(child: Text(label, style: labelStyle)),
                        const SizedBox(width: _gap),
                        Text(
                          value,
                          textAlign: TextAlign.end,
                          style: valueStyle,
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: labelStyle),
                      const SizedBox(height: 2),
                      Text(value, style: valueStyle),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
