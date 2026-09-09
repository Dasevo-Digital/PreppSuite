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
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    trailing: Text(value, textAlign: TextAlign.end),
  );
}
