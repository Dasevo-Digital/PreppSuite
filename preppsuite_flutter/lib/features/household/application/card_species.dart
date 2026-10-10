/// Whose card it is: a person's, or an animal's (#151).
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';

/// What kind of animal a card is for. Stored by name in
/// `HouseholdMembers.species`; a person's card stores nothing.
///
/// Three, and the third is a catch-all on purpose: what a dog and a cat
/// need is what the checklists and the head counts already distinguish,
/// and a rabbit, a budgie and a tortoise need what their own card says.
enum CardSpecies { dog, cat, other }

extension CardKind on HouseholdMember {
  /// Whether this card is an animal's. A species this version does not
  /// know -- written by a newer one -- is still an animal, never a person.
  bool get isAnimal => species != null;

  /// The kind of animal, or null for a person; [CardSpecies.other] for a
  /// name this version does not know.
  CardSpecies? get cardSpecies => species == null
      ? null
      : CardSpecies.values.asNameMap()[species] ?? CardSpecies.other;
}

String localizeCardSpecies(AppLocalizations l10n, CardSpecies species) =>
    switch (species) {
      CardSpecies.dog => l10n.cardSpeciesDog,
      CardSpecies.cat => l10n.cardSpeciesCat,
      CardSpecies.other => l10n.cardSpeciesOther,
    };
