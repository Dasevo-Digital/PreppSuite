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
///
/// That contract has a cost the phone should not pay. A block is
/// all-or-nothing, so a room holding two hundred photographed things is
/// one block, and the [ListView] below builds it whole — measured on a
/// 400 by 800 screen showing six tiles, a household of 300 things in
/// three rooms decoded **100 pictures** and held 10.5 MB, because the
/// first room's block reached into the viewport and blocks have no
/// inside. [AdaptiveSection] is the way out: one block while there are
/// columns to be separated by, and taken apart again when there is only
/// one.
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
  /// [columnWidth] and [spacing] between them. Also what a grid of cards
  /// that is not a page of blocks asks, such as the Kiwix library.
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
        List<Widget> spaced(List<Widget> lane, {bool unpack = false}) {
          final out = <Widget>[];
          for (var index = 0; index < lane.length; index++) {
            if (index > 0) out.add(SizedBox(height: spacing));
            final block = lane[index];
            // One column means nothing has to be kept together, so a
            // section becomes its own parts and the list goes back to
            // building only what is on screen.
            if (unpack && block is AdaptiveSection) {
              out.addAll(block.parts);
            } else {
              out.add(block);
            }
          }
          return out;
        }

        // The narrow case stays the plain scrolling column it was, with a
        // ListView that only builds what is on screen.
        if (columns == 1) {
          return ListView(
            padding: padding,
            children: spaced(blocks, unpack: true),
          );
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

/// A heading and the rows under it, as one block that can be taken apart.
///
/// Inside [AdaptiveColumns] this is a block like any other while there is
/// more than one column: heading and rows stay together, because a room's
/// name in one column and its contents in the next is not a layout, it is
/// a bug. With a single column there is nothing to be separated by, so
/// [AdaptiveColumns] unpacks it and the [ListView] builds only the rows
/// that are on screen.
///
/// That is the whole point. A block is all-or-nothing, and a room with two
/// hundred photographed things in it is one block — which is how a phone
/// came to decode a hundred pictures to show six.
class AdaptiveSection extends StatelessWidget {
  const AdaptiveSection({
    super.key,
    this.heading,
    required this.rows,
    this.headingSpacing = 8,
  });

  final Widget? heading;

  /// Expected to space themselves — a [Card] brings its own margin. Rows
  /// are placed one after another with nothing between them, so that the
  /// unpacked list looks exactly like the packed column.
  final List<Widget> rows;

  final double headingSpacing;

  /// This section as a flat run of widgets, spaced as [build] spaces them.
  List<Widget> get parts => [
    if (heading case final text?) ...[
      text,
      SizedBox(height: headingSpacing),
    ],
    ...rows,
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: parts,
  );
}
