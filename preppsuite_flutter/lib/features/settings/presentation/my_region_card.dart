import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import '../../household/application/warning_feed_countries.dart';
import '../../warnings/application/dwd_areas_provider.dart';

/// The household's own country and region.
///
/// Every "is the caller the owner" check is gone: there is one user, on one
/// device, and nobody to ask permission from.
class MyRegionCard extends ConsumerWidget {
  const MyRegionCard({super.key, required this.profile, required this.l10n});

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        // The key written out, not just printed. `031010000000` is
        // unverifiable — it is exactly as plausible as the key for
        // somewhere else entirely, so somebody checking whether their
        // region is right had nothing to check against. The number stays
        // alongside the name: it is what the BBK endpoint is asked for,
        // and what a person compares against a table if they go looking.
        subtitle: Text(_regionSubtitle(ref)),
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

  String _regionSubtitle(WidgetRef ref) {
    final key = profile.regionKey;
    if (key == null) return l10n.settingsNoRegionSet;

    final described = describeRegionKey(
      ref.watch(dwdAreasProvider).value,
      key,
    );
    // While the table is still loading, and for a key it does not know.
    // The second case is worth saying rather than passing over: a key
    // that names no district matches no warning either.
    return described == null
        ? '$key — ${l10n.settingsRegionUnknownKey}'
        : '$described ($key)';
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

  /// Set when the field holds something that could never match a
  /// warning. It used to accept anything: five letters passed the
  /// `length >= 5` test the region filter uses, so typing a town's name
  /// switched filtering on and then matched nothing.
  String? _error;

  @override
  void dispose() {
    _regionKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final region = _regionKeyController.text.trim();

    // Empty clears the region, which is a legitimate choice — it means
    // "show me everything".
    if (_countryCode == 'DE' &&
        region.isNotEmpty &&
        !RegExp(r'^\d{5}(\d{7})?$').hasMatch(region)) {
      setState(
        () => _error = AppLocalizations.of(context)!.settingsRegionKeyInvalid,
      );
      return;
    }

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
                  errorText: _error,
                ),
                keyboardType: TextInputType.number,
                // Rebuilds so the name below the field follows what is
                // being typed: the point of showing it at all is that the
                // person can see they have the right place before saving.
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 8),
              _KeyPreview(
                regionKey: _regionKeyController.text.trim(),
                l10n: l10n,
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

/// What the key in the field currently names.
class _KeyPreview extends ConsumerWidget {
  const _KeyPreview({required this.regionKey, required this.l10n});

  final String regionKey;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (regionKey.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final described = describeRegionKey(
      ref.watch(dwdAreasProvider).value,
      regionKey,
    );

    return Row(
      children: [
        Icon(
          described == null ? Icons.help_outline : Icons.place_outlined,
          size: 18,
          color: described == null
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            described ?? l10n.settingsRegionUnknownKey,
            style: theme.textTheme.bodySmall?.copyWith(
              color: described == null ? theme.colorScheme.error : null,
            ),
          ),
        ),
      ],
    );
  }
}

AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context)!;
