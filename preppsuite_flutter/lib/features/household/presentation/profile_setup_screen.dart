import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../application/household_providers.dart';
import '../application/warning_feed_countries.dart';
import 'count_tile.dart';

/// What the household is called and where it is.
///
/// There is no account to create and no server to point at. What there
/// *is*, since the second device became a normal thing, is the question
/// of whether this household already exists somewhere else — see
/// [SetupChoiceScreen]. This screen fills in the part that belongs to
/// this device either way, and [onFilled] decides what happens with it.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({
    super.key,
    this.onFilled,
    this.intro,
    this.submitLabel,
    this.initialName,
    this.initialCountryCode,
  });

  /// Called instead of creating the profile outright.
  ///
  /// Null means the ordinary first run: create the household here and
  /// now. The joining routes pass a callback because for them creating
  /// is only the first half — the household id still has to be adopted
  /// from a folder or from another device.
  final Future<void> Function(HouseholdProfile profile)? onFilled;

  /// Replaces the standard introduction where the route needs to explain
  /// itself instead.
  final String? intro;

  final String? submitLabel;

  /// What a shared folder already says the household is called.
  final String? initialName;
  final String? initialCountryCode;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialName ?? '',
  );
  final _regionController = TextEditingController();
  late String _countryCode = widget.initialCountryCode ?? 'DE';
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
    final profile = await ref
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
    final next = widget.onFilled;
    if (next == null) return;
    try {
      await next(profile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
                      widget.intro ?? l10n.profileSetupIntro,
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
                      child: Text(
                        widget.submitLabel ?? l10n.profileSetupSubmit,
                      ),
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
