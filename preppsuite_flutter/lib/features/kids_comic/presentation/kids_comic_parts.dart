/// The pieces every page of the comic is built from.
library;

import 'package:flutter/material.dart';

import '../application/kids_comic.dart';

/// A scrolling column of readable width, centred on a wide window.
class ComicReadable extends StatelessWidget {
  const ComicReadable({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

class ComicPanelView extends StatelessWidget {
  const ComicPanelView({
    super.key,
    required this.panel,
    required this.speakers,
  });

  final ComicPanel panel;
  final Map<ComicSpeaker, String> speakers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: ink, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ComicPicture(
            asset: panel.asset,
            description: panel.description,
            aspectRatio: panel.wide ? 600 / 180 : 300 / 180,
          ),
          Container(height: 2.5, color: ink),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, line) in panel.lines.indexed) ...[
                  if (i > 0) const SizedBox(height: 10),
                  line.isCaption
                      ? _Caption(line: line)
                      : _Bubble(line: line, name: speakers[line.speaker]!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComicPicture extends StatelessWidget {
  const ComicPicture({
    super.key,
    required this.asset,
    required this.description,
    required this.aspectRatio,
  });

  final String asset;
  final String description;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) => AspectRatio(
    // Fixed before the picture has loaded, so the page does not jump as
    // each one arrives.
    aspectRatio: aspectRatio,
    child: Image.asset(
      asset,
      fit: BoxFit.cover,
      semanticLabel: description,
      // A missing picture costs the picture, never the words under it.
      errorBuilder: (context, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    ),
  );
}

/// Each speaker's colour on the name tag, so a child who cannot read yet
/// still sees who is talking. The same colours as the drawings: Mila's
/// shirt, Nuss's fur, Papa's jumper, the neighbour's cardigan.
const _tagColours = {
  ComicSpeaker.mila: (Color(0xFFF2C21B), Color(0xFF1D2433)),
  ComicSpeaker.nuss: (Color(0xFFB85A1E), Color(0xFFFFFFFF)),
  ComicSpeaker.papa: (Color(0xFF3F7A59), Color(0xFFFFFFFF)),
  ComicSpeaker.neighbour: (Color(0xFF7D4FA6), Color(0xFFFFFFFF)),
};

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line, required this.name});

  final ComicLine line;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (tag, onTag) = _tagColours[line.speaker]!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outline, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: tag,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  name.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onTag,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            TextSpan(text: line.text),
          ],
        ),
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.line});

  final ComicLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = line.lead;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: theme.colorScheme.tertiaryContainer,
      child: Text.rich(
        TextSpan(
          children: [
            if (lead != null)
              TextSpan(
                text: line.text.isEmpty ? lead : '$lead ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            TextSpan(text: line.text),
          ],
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}
