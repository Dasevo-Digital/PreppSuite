import 'package:flutter/material.dart';

/// Lays a page out in as many columns as the window has room for.
///
/// A desktop window is wider than anything worth reading in one line. On a
/// 1500 px window the energy screen put "Strom" at the left edge and
/// "14 Tage" at the right, 1400 px apart — two halves of one sentence that
/// the eye cannot join — while the page itself scrolled, with the space it
/// needed sitting unused beside it. Stretching one column is not using the
/// space, it is wasting it in the other direction.
///
/// So the page is cut into columns of readable width instead, and the
/// window's width decides how many. A phone gets exactly what it got
/// before: one column, an ordinary [ListView], nothing lazy given up.
///
/// [blocks] and not "children" on purpose: a block is whatever has to stay
/// together — a heading with the list under it, a card with its caption.
/// Whole blocks are dealt into the columns in order, so a heading can
/// never end up in one column with its list in the next.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({
    super.key,
    required this.blocks,
    this.padding = EdgeInsets.zero,
    this.columnWidth = 560,
    this.maxColumns = 3,
    this.spacing = 24,
  });

  /// The page's sections, each of which stays in one piece.
  final List<Widget> blocks;

  final EdgeInsetsGeometry padding;

  /// The widest a column is allowed to get before another one is opened.
  ///
  /// 560 is on the generous side of the usual advice for a text measure,
  /// because most of what is in these columns is a list of short rows
  /// rather than prose.
  final double columnWidth;

  /// Past this the page reads as a newspaper rather than an app, and the
  /// eye loses which column it was in.
  final int maxColumns;

  final double spacing;

  /// How much wider than [columnWidth] a column may be stretched before
  /// the layout stops widening and centres itself instead.
  ///
  /// Without this the rule eats itself on a very wide screen: a 2754 px
  /// window allows three columns, which then share the whole width and
  /// come out at 891 px each — the same too-long line the columns were
  /// there to avoid, three times over. So the columns fill the window
  /// while they stay readable, and beyond that the leftover becomes
  /// margin. "Use the whole width" is the means here, not the goal.
  static const _stretch = 1.25;

  /// How many columns [width] has room for, given a column of
  /// [columnWidth] and [spacing] between them.
  @visibleForTesting
  static int columnsFor(
    double width, {
    double columnWidth = 560,
    double spacing = 24,
    int maxColumns = 3,
  }) {
    if (!width.isFinite || width <= 0) return 1;
    final fits = ((width + spacing) / (columnWidth + spacing)).floor();
    return fits.clamp(1, maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(
          constraints.maxWidth - padding.horizontal,
          columnWidth: columnWidth,
          spacing: spacing,
          maxColumns: maxColumns,
        );

        // Blocks are spaced by the layout rather than by each caller, so
        // the gap between two sections is the same one everywhere and
        // cannot be forgotten between them.
        List<Widget> spaced(List<Widget> lane) => [
          for (var index = 0; index < lane.length; index++) ...[
            if (index > 0) SizedBox(height: spacing),
            lane[index],
          ],
        ];

        // The narrow case stays the plain scrolling column it was, with a
        // ListView that only builds what is on screen.
        if (columns == 1) {
          return ListView(padding: padding, children: spaced(blocks));
        }

        final widest = columns * (columnWidth * _stretch + spacing) - spacing;

        final lanes = [for (var i = 0; i < columns; i++) <Widget>[]];
        for (var index = 0; index < blocks.length; index++) {
          lanes[index % columns].add(blocks[index]);
        }

        return SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widest),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var lane = 0; lane < columns; lane++) ...[
                    if (lane > 0) SizedBox(width: spacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: spaced(lanes[lane]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
