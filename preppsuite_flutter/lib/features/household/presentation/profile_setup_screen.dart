import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/household_providers.dart';
import '../application/warning_feed_countries.dart';
import 'count_tile.dart';

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
  int _children = 0;
  int _dogs = 0;
  int _cats = 0;
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
          children: _children,
          dogs: _dogs,
          cats: _cats,
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
                      isExpanded: true,
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
                    // All four, and named the same as on the household
                    // screen. This asked for "Personen im Haushalt" and
                    // stored the answer as the number of adults, so a
                    // family of two with two children entered 4 — which is
                    // what the label asked for — and got a supply target
                    // for four adults. Children need less, pets need
                    // something else again, and none of it was asked until
                    // somebody found the household screen by themselves.
                    //
                    // These are the whole input to the supply calculation,
                    // and it is the first number the app shows.
                    CountTile(
                      icon: Icons.people_outline,
                      label: l10n.householdAdultsLabel,
                      value: _personCount,
                      minimum: 1,
                      onChanged: (value) =>
                          setState(() => _personCount = value),
                    ),
                    CountTile(
                      icon: Icons.child_care_outlined,
                      label: l10n.householdChildrenLabel,
                      value: _children,
                      onChanged: (value) => setState(() => _children = value),
                    ),
                    CountTile(
                      icon: Icons.pets_outlined,
                      label: l10n.householdDogsLabel,
                      value: _dogs,
                      onChanged: (value) => setState(() => _dogs = value),
                    ),
                    CountTile(
                      icon: Icons.pets,
                      label: l10n.householdCatsLabel,
                      value: _cats,
                      onChanged: (value) => setState(() => _cats = value),
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
