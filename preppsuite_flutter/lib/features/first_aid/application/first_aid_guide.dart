/// The shape of one first aid instruction.
///
/// Deliberately not in the database and not in the ARB files.
///
/// Not the database, because this is not household data: nobody edits it,
/// nothing syncs it, and a guide that arrived by sync from a device
/// running an older version would be worse than no guide at all.
///
/// Not the ARB files, because medical text has to be reviewable as prose.
/// Fifteen guides are about two hundred strings; scattered through eleven
/// hundred lines of interface wording, nobody could ever read them end to
/// end and check them against the guideline they came from. They live in
/// `first_aid_guides_de.dart` and `first_aid_guides_en.dart` instead, one
/// file per language, each readable in one sitting.
/// `first_aid_guides_test.dart` holds the two files to the same ids and
/// the same step counts, which is the part a compiler cannot check.
library;

/// Where a guide sits in the list.
///
/// The order is the order of the list on screen, and it is triage order,
/// not alphabetical: what kills in minutes comes first.
enum FirstAidGroup {
  /// Making the call, and the check that comes before everything else.
  basics,

  /// Minutes matter and the bystander is the treatment.
  lifeThreatening,

  /// Bleeding, burns, breaks.
  injury,

  /// Strokes, heart attacks, seizures, allergies.
  illness,

  /// Cold, heat, poison.
  environment,
}

/// A picture the app draws itself.
///
/// Line art rather than photographs or video stills: a few hundred bytes
/// of code each, sharp at any size, correct in the dark theme, and — the
/// part that actually matters — legible at arm's length on a floor. See
/// `presentation/first_aid_drawings.dart`.
enum FirstAidDrawing {
  /// Where the hands go on the chest.
  compressionPoint,

  /// The recovery position, seen from above.
  recoveryPosition,

  /// Back blows and abdominal thrusts.
  choking,

  /// Direct pressure on a wound.
  bleeding,

  /// The drooping face of a stroke.
  face,
}

/// One instruction. Short enough to read in a glance, because that is all
/// the attention there will be.
class FirstAidStep {
  const FirstAidStep(this.text, {this.detail});

  /// The imperative. One action.
  final String text;

  /// The number, the depth, the count — everything that turns the action
  /// into a correct action. Shown smaller, under the step.
  final String? detail;
}

/// A labelled value: a rate, a depth, a telephone number.
class FirstAidFact {
  const FirstAidFact(this.label, this.value);

  final String label;
  final String value;
}

/// One first aid instruction, start to finish.
class FirstAidGuide {
  const FirstAidGuide({
    required this.id,
    required this.group,
    required this.title,
    required this.when,
    required this.steps,
    required this.source,
    this.callFirst = false,
    this.cautions = const [],
    this.facts = const [],
    this.drawing,
    this.hasPacer = false,
  });

  /// Stable across versions and across languages. It is what a video in a
  /// downloaded pack names to say which guide it belongs to, so renaming
  /// one orphans every video that pointed at it.
  final String id;

  final FirstAidGroup group;

  /// What the guide is called.
  final String title;

  /// One line: how to recognise that this is the guide you want. The list
  /// shows it under the title, because in the moment the title alone is
  /// rarely enough to choose by.
  final String when;

  /// Whether 112 comes before the steps rather than inside them.
  final bool callFirst;

  final List<FirstAidStep> steps;

  /// The things that make it worse. Shown apart from the steps and after
  /// them — mixed in, a "never" reads as a "do" to someone skimming.
  final List<String> cautions;

  /// Numbers worth having in front of you while you work.
  final List<FirstAidFact> facts;

  final FirstAidDrawing? drawing;

  /// Whether this guide offers the compression pacer.
  final bool hasPacer;

  /// Where the instruction comes from, named on the screen.
  ///
  /// The same rule the blackout figures follow: this app states no
  /// medical advice of its own, and where it repeats somebody else's it
  /// says whose. See `outage_food_safety.dart`.
  final String source;
}
