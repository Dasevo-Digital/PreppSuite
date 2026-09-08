import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import '../../household/application/warning_feed_countries.dart';

/// The household's own country and region.
///
/// Every "is the caller the owner" check is gone: there is one user, on one
/// device, and nobody to ask permission from.
class MyRegionCard extends StatelessWidget {
  const MyRegionCard({super.key, required this.profile, required this.l10n});

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final country = warningFeedCountries.firstWhere(
      (c) => c.code == profile.countryCode,
      orElse: () => WarningFeedCountry(
        profile.countryCode,
        profile.countryCode,
        profile.countryCode,
      ),
    );
    final countryName = Localizations.localeOf(context).languageCode == 'de'
        ? country.nameDe
        : country.nameEn;

    return Card(
      child: ListTile(
        title: Text(countryName),
        subtitle: Text(profile.regionKey ?? l10n.settingsNoRegionSet),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: l10n.csvImportEditRowTooltip,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => _EditRegionDialog(profile: profile),
          ),
        ),
      ),
    );
  }
}

class _EditRegionDialog extends ConsumerStatefulWidget {
  const _EditRegionDialog({required this.profile});

  final HouseholdProfile profile;

  @override
  ConsumerState<_EditRegionDialog> createState() => _EditRegionDialogState();
}

class _EditRegionDialogState extends ConsumerState<_EditRegionDialog> {
  late final TextEditingController _regionKeyController = TextEditingController(
    text: widget.profile.regionKey ?? '',
  );
  late String _countryCode = widget.profile.countryCode;
  @override
  void dispose() {
    _regionKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final region = _regionKeyController.text.trim();
    await ref
        .read(householdProfileProvider.notifier)
        .save(
          widget.profile.copyWith(
            countryCode: _countryCode,
            regionKey: region.isEmpty ? null : region,
            clearRegionKey: region.isEmpty,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settingsMyRegionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _countryCode,
              decoration: InputDecoration(labelText: l10n.countryLabel),
              items: [
                for (final country in warningFeedCountries)
                  DropdownMenuItem(
                    value: country.code,
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'de'
                          ? country.nameDe
                          : country.nameEn,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _countryCode = value ?? _countryCode),
            ),
            if (_countryCode == 'DE') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _regionKeyController,
                decoration: InputDecoration(
                  labelText: l10n.regionKeyLabel,
                  helperText: l10n.regionKeyHelper,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}
