/// The small parts the screens are built from.
///
/// Three of them, and each exists because the stock widget that stood in
/// its place cost more than it gave. A `Chip` in a list row is a stack of
/// some twenty-five elements with an ink well, a tooltip and an animation
/// controller, for a word that nobody taps; a `CircleAvatar` is an animated
/// container around an icon. These are boxes with text in them: no ticker,
/// no ink, no layer of their own, so they can stand in every row of a long
/// list. See "Was eine Liste je Zeile kostet" in ARCHITEKTUR.md.
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// An icon on a soft square, at the head of a row.
///
/// It is what gives a list of grey entries a left edge to run down, and
/// the eye something to find a line by.
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.background,
    this.foreground,
    this.size = 40,
  });

  final IconData icon;

  /// A pair, like the severity colours. Left out it is the app's own tone.
  final Color? background;
  final Color? foreground;

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background ?? scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Icon(
          icon,
          size: size * 0.55,
          color: foreground ?? scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// A word that says the state of a row: "abgelaufen", "niedriger Bestand".
///
/// Not a button, and it must not look like one: the pill has no outline,
/// and it is only as high as its text, so a row with a tag is not half as
/// tall again as the row beside it.
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  /// The ochre of something to see to soon.
  factory StatusTag.attention(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return StatusTag(
      label: label,
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
    );
  }

  /// The red of something that is already wrong.
  factory StatusTag.problem(
    BuildContext context,
    String label, {
    IconData? icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return StatusTag(
      label: label,
      icon: icon,
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    );
  }

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        // A row rather than an icon set into the text: a span of that kind
        // puts an object character into the string, and a screen reader
        // announces it.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final icon?) ...[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: AppSpace.xs),
            ],
            Flexible(child: Text(label, style: style)),
          ],
        ),
      ),
    );
  }
}

/// A thin bar for how far something has got.
///
/// Two boxes, one inside the other. `LinearProgressIndicator` is a custom
/// painter with an animation controller behind it, which is the right
/// tool for something that moves; this does not, and one stands in each
/// row of a list. The caller says what it means to a screen reader:
/// usually the figure beside it already does.
class ThinMeter extends StatelessWidget {
  const ThinMeter({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  /// Between 0 and 1.
  final double value;

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(height / 2);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Ochre until the value is reached, green once it is.
                color: color ?? (value >= 1 ? scheme.primary : scheme.tertiary),
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The heading of a group of rows.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.padding});

  final String title;

  /// Left out, it sits on the page margin with room above it.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.fromLTRB(
            AppSpace.xs,
            AppSpace.xl,
            AppSpace.xs,
            AppSpace.sm,
          ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
