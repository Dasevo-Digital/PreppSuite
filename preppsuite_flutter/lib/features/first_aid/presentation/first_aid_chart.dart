import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/first_aid_guide.dart';

/// A guide's chart, small, with a magnifier that opens it full size.
///
/// Small because the steps are right underneath and are what is read; the
/// chart is for taking in the whole guide at a glance, and for showing
/// somebody else. Its height is fixed before the picture has loaded, so
/// the steps below do not jump down when it arrives.
class FirstAidChartThumbnail extends StatelessWidget {
  const FirstAidChartThumbnail({
    super.key,
    required this.guide,
    this.height = 220,
  });

  final FirstAidGuide guide;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final chart = guide.chart!;
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FirstAidChartScreen(title: guide.title, chart: chart),
      ),
    );

    // A fixed box, so that neither the steps below nor the magnifier move
    // when the picture arrives. The charts are drawn upright, between 2:3
    // and 4:5; each sits centred in a box of 3:4.
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: height,
        width: height * 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The picture opens the chart too, but a screen reader is
            // told about one button only: the magnifier, which says what
            // it does.
            ExcludeSemantics(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Material(
                    color: scheme.surfaceContainerHighest,
                    child: InkWell(
                      onTap: open,
                      child: Image.asset(
                        chart,
                        fit: BoxFit.contain,
                        // Decoded at the size it is shown, not at its full
                        // 1500 pixels: that is for the full screen.
                        cacheHeight:
                            (height * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        errorBuilder: (context, _, _) =>
                            const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(
                onPressed: open,
                tooltip: l10n.firstAidChartOpen,
                icon: const Icon(Icons.zoom_in),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chart on its own, as large as the screen allows, to be zoomed into.
class FirstAidChartScreen extends StatelessWidget {
  const FirstAidChartScreen({
    super.key,
    required this.title,
    required this.chart,
  });

  final String title;
  final String chart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          child: Center(
            child: Image.asset(
              chart,
              fit: BoxFit.contain,
              semanticLabel: title,
              errorBuilder: (context, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
