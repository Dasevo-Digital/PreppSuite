import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/app_tour.dart';
import '../application/app_tour_l10n.dart';

/// The band at the foot of the shell while the tour runs (#173).
///
/// It sits in the shell's column rather than over it: the screen above
/// gets less height instead of having its last row and its floating
/// button covered, and stays usable — whoever wants to set something up
/// at a stop does it there and then and taps "next" afterwards. That is
/// also why the band carries no buttons of its own beyond the tour's:
/// the text names the screen's real ones.
///
/// The text has a ceiling and scrolls under it, so that at twice the
/// font size the band cannot take the screen it is describing; the
/// buttons stay below it, always in reach. The scrollbar stays visible
/// while there is more to read, because a cut-off line alone is easily
/// taken for the end of the text.
class TourBanner extends ConsumerStatefulWidget {
  const TourBanner({super.key, required this.onFinished});

  /// Called after the last stop, to hand the household back to the
  /// overview rather than leave it in the settings.
  final VoidCallback onFinished;

  @override
  ConsumerState<TourBanner> createState() => _TourBannerState();
}

class _TourBannerState extends ConsumerState<TourBanner> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Each stop starts at its own first line, not at wherever the last
    // one was scrolled to.
    ref.listen(appTourProvider, (_, _) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
    final stop = ref.watch(appTourProvider);
    if (stop == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tour = ref.read(appTourProvider.notifier);
    final textCeiling = MediaQuery.sizeOf(context).height * 0.16;

    return Material(
      color: colors.secondaryContainer,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Read out on arrival, with the step: the screen
                      // behind changed as well, and this says to what.
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          header: true,
                          child: Text(
                            tourStopTitle(l10n, stop),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                      // "3/8" to the eye, the words to the ear. A line of
                      // its own cost the band its height at large text.
                      Semantics(
                        label: l10n.tourProgress(
                          stop.index + 1,
                          TourStop.values.length,
                        ),
                        excludeSemantics: true,
                        child: Text(
                          '${stop.index + 1}/${TourStop.values.length}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l10n.tourEnd,
                        color: colors.onSecondaryContainer,
                        onPressed: tour.end,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: textCeiling),
                    child: Scrollbar(
                      controller: _scroll,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          tourStopBody(l10n, stop),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      spacing: 8,
                      overflowSpacing: 4,
                      children: [
                        if (!stop.isFirst)
                          TextButton(
                            onPressed: tour.back,
                            child: Text(l10n.tourBack),
                          ),
                        FilledButton(
                          onPressed: () {
                            if (stop.isLast) {
                              tour.end();
                              widget.onFinished();
                            } else {
                              tour.next();
                            }
                          },
                          child: Text(
                            stop.isLast ? l10n.tourDone : l10n.tourNext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
