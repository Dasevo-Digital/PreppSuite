import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/household_providers.dart';
import '../application/warning_feed_countries.dart';

/// First run: name the household and say where it is.
///
/// This is all the setup there is now. There is no account to create, no
/// server to point at and no invite code to type — the app works the
/// moment this is filled in.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  String _countryCode = 'DE';
  int _personCount = 1;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final region = _regionController.text.trim();
    await ref
        .read(householdProfileProvider.notifier)
        .create(
          name: _nameController.text.trim(),
          countryCode: _countryCode,
          regionKey: region.isEmpty ? null : region,
          personCount: _personCount,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isGerman = _countryCode == 'DE';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileSetupTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.profileSetupIntro,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.householdNameLabel,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? l10n.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _countryCode,
                      decoration: InputDecoration(
                        labelText: l10n.countryLabel,
                      ),
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
                    // The Kreisschlüssel only means anything in Germany —
                    // asking an Austrian household for one would be noise.
                    if (isGerman) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _regionController,
                        decoration: InputDecoration(
                          labelText: l10n.regionKeyLabel,
                          helperText: l10n.regionKeyHelper,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Text(l10n.personCountLabel)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          tooltip: l10n.stepperDecrease(l10n.personCountLabel),
                          onPressed: _personCount > 1
                              ? () => setState(() => _personCount--)
                              : null,
                        ),
                        Text(
                          '$_personCount',
                          style: Theme.of(context).textTheme.titleMedium,
                          semanticsLabel: l10n.stepperValue(
                            l10n.personCountLabel,
                            _personCount,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: l10n.stepperIncrease(l10n.personCountLabel),
                          onPressed: () => setState(() => _personCount++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: Text(l10n.profileSetupSubmit),
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
