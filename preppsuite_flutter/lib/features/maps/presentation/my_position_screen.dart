import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/readable_position.dart';

/// Where I am, in a form somebody else can write down.
///
/// The map could always centre on the blue dot. That is enough to look at
/// and no use at all on the telephone: "I am at the dot" gets nobody sent
/// anywhere, and reading a decimal fraction digit by digit over a bad line
/// is how a crew ends up in the next valley.
///
/// Four spellings of one point, ordered by who is listening rather than by
/// precision. Degrees and minutes first, because that is what a German
/// control room asks for and reads back.
///
/// Every line can be copied, and all of it is computed on the device —
/// this screen is wanted exactly when there is no network.
class MyPositionScreen extends StatefulWidget {
  const MyPositionScreen({super.key, this.geolocation, this.initial});

  /// Injectable so the screen can be shown without a receiver.
  final GeolocationService? geolocation;

  /// A position that is already known — a point picked on the map, say.
  /// With one, the screen does not ask the receiver at all.
  final ReadablePosition? initial;

  @override
  State<MyPositionScreen> createState() => _MyPositionScreenState();
}

class _MyPositionScreenState extends State<MyPositionScreen> {
  late final GeolocationService _geolocation =
      widget.geolocation ?? GeolocationService();

  ReadablePosition? _position;
  String? _failure;
  var _measuring = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initial;
    if (_position == null) _measure();
  }

  @override
  void dispose() {
    if (widget.geolocation == null) _geolocation.close();
    super.dispose();
  }

  Future<void> _measure() async {
    setState(() {
      _measuring = true;
      _failure = null;
    });
    try {
      final fix = await _geolocation.getCurrentFix();
      if (!mounted) return;
      setState(() => _position = fix);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _failure = describeError(AppLocalizations.of(context)!, error),
      );
    } finally {
      if (mounted) setState(() => _measuring = false);
    }
  }

  void _copy(String value) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.myPositionCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final position = _position;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPositionTitle),
        actions: [
          IconButton(
            onPressed: _measuring ? null : _measure,
            tooltip: l10n.myPositionMeasure,
            icon: _measuring
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AdaptiveColumns(
        padding: const EdgeInsets.all(16),
        blocks: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.myPositionIntro, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(l10n.myPositionOffline, style: theme.textTheme.bodySmall),
              if (_failure case final failure?) ...[
                const SizedBox(height: 12),
                Text(
                  failure,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              // What the fix is worth, said before anything is read out.
              // Ten metres is a doorway; eight hundred is the wrong end of
              // the village, and a number without that is a claim without
              // a confidence.
              if (position?.accuracyMetres case final metres?) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.myPositionAccuracy(metres.round()),
                  style: theme.textTheme.titleSmall,
                ),
                if (metres > 50)
                  Text(
                    l10n.myPositionAccuracyPoor,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ],
          ),
          if (position != null) ...[
            _Line(
              title: l10n.myPositionDms,
              hint: l10n.myPositionDmsHint,
              value: position.degreesMinutesSeconds,
              onCopy: _copy,
            ),
            _Line(
              title: l10n.myPositionUtm,
              hint: l10n.myPositionUtmHint,
              value: position.utm,
              onCopy: _copy,
            ),
            _Line(
              title: l10n.myPositionMgrs,
              hint: l10n.myPositionMgrsHint,
              value: position.mgrs,
              onCopy: _copy,
            ),
            _Line(
              title: l10n.myPositionPlusCode,
              hint: l10n.myPositionPlusCodeHint,
              value: position.plusCode,
              onCopy: _copy,
            ),
            _Line(
              title: l10n.myPositionDecimal,
              hint: l10n.myPositionDecimalHint,
              value: position.decimal,
              onCopy: _copy,
            ),
          ],
        ],
      ),
    );
  }
}

/// One spelling of the point, big enough to read off the screen.
class _Line extends StatelessWidget {
  const _Line({
    required this.title,
    required this.hint,
    required this.value,
    required this.onCopy,
  });

  final String title;
  final String hint;
  final String value;
  final void Function(String) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  onPressed: () => onCopy(value),
                  tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                  icon: const Icon(Icons.copy_outlined),
                ),
              ],
            ),
            SelectableText(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                // Figures of one width, so a digit read aloud twice is
                // found again in the same place on the line.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(hint, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
