import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import '../application/household_exception_l10n.dart';
import '../application/household_providers.dart';
import '../application/warning_feed_countries.dart';

class CreateHouseholdScreen extends ConsumerStatefulWidget {
  const CreateHouseholdScreen({super.key});

  @override
  ConsumerState<CreateHouseholdScreen> createState() =>
      _CreateHouseholdScreenState();
}

class _CreateHouseholdScreenState extends ConsumerState<CreateHouseholdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionKeyController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _countryCode = 'DE';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _regionKeyController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _showRegionKeyExplanation(AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.regionKeyExplanationTitle),
        content: SingleChildScrollView(
          child: Text(l10n.regionKeyExplanationBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.regionKeyExplanationClose),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await client.household.createHousehold(
        name: _nameController.text.trim(),
        countryCode: _countryCode,
        regionKey: _regionKeyController.text.trim().isEmpty
            ? null
            : _regionKeyController.text.trim(),
        displayName: _displayNameController.text.trim(),
      );
      ref.invalidate(myHouseholdProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      setState(() => _errorMessage = localizeHouseholdError(l10n, error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createHouseholdTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.householdNameLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _countryCode,
                      decoration: InputDecoration(labelText: l10n.countryLabel),
                      items: [
                        for (final country in warningFeedCountries)
                          DropdownMenuItem(
                            value: country.code,
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'de'
                                  ? country.nameDe
                                  : country.nameEn,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _countryCode = value ?? 'DE'),
                    ),
                    if (_countryCode == 'DE') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regionKeyController,
                        decoration: InputDecoration(
                          labelText: l10n.regionKeyLabel,
                          helperText: l10n.regionKeyHelper,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.info_outline),
                            tooltip: l10n.regionKeyExplanationTooltip,
                            onPressed: () => _showRegionKeyExplanation(l10n),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: l10n.displayNameLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.fieldRequired
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : () => _submit(l10n),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.createButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
