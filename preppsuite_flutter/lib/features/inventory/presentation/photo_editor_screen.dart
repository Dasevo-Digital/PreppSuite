import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/photo_edit.dart';
import '../../../core/photo_vault.dart';

/// Turn and trim a photo before it goes into the inventory.
///
/// Pops the edited JPEG bytes, or null if the edit was abandoned — the
/// caller decides where the file lands, so nothing here can overwrite the
/// original before the user has said yes.
class PhotoEditorScreen extends StatefulWidget {
  const PhotoEditorScreen({super.key, required this.file});

  final File file;

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  var _edit = const PhotoEdit();
  bool _saving = false;
  Uint8List? _bytes;

  /// Nothing to press while the picture is still loading or being
  /// written — including "save", which would dereference bytes that are
  /// not there yet.
  bool get _busy => _saving || _bytes == null;

  /// The picture's own proportions.
  ///
  /// Needed before anything can be drawn: the crop rectangle is a
  /// fraction of the *picture*, so the box it is dragged in has to be the
  /// picture and not the letterboxed area around it. Cropping against the
  /// wrong box would cut somewhere other than where the frame was.
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Through the vault: the stored picture is sealed, and the editor
    // works on the image inside it.
    final bytes = await const PhotoVault().read(widget.file);
    if (bytes == null) {
      // Gone, or sealed under a key this installation does not hold.
      // Nothing to edit, and staying would leave a spinner for ever.
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final image = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _aspectRatio = image.width / image.height;
    });
    image.dispose();
  }

  void _rotate(int turns) {
    // The rectangle was drawn on the old orientation and means something
    // else on the new one, so it goes back to the whole picture rather
    // than to a rotated guess at what was meant.
    setState(
      () => _edit = PhotoEdit(quarterTurns: _edit.quarterTurns + turns),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Off the main isolate: a twelve-megapixel photo takes long enough to
    // decode and re-encode that doing it here drops frames.
    final edited = await _applyOffThread(_bytes!, _edit);

    if (!mounted) return;
    if (edited == null) {
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoEditFailed)));
      return;
    }
    navigator.pop(edited);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.photoEditTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_left),
            tooltip: l10n.photoEditRotateLeft,
            onPressed: _busy ? null : () => _rotate(-1),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: l10n.photoEditRotateRight,
            onPressed: _busy ? null : () => _rotate(1),
          ),
          IconButton(
            icon: const Icon(Icons.crop_free),
            tooltip: l10n.photoEditReset,
            onPressed: _busy
                ? null
                : () => setState(() => _edit = const PhotoEdit()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: switch ((_bytes, _aspectRatio)) {
                  (final Uint8List bytes, final double ratio) => RotatedBox(
                    quarterTurns: _edit.quarterTurns,
                    child: AspectRatio(
                      aspectRatio: ratio,
                      child: _CropArea(
                        // Fill and not contain: the box already has the
                        // picture's proportions, so there is nothing to
                        // letterbox and the two cannot disagree.
                        image: Image.memory(bytes, fit: BoxFit.fill),
                        crop: _edit.crop,
                        onChanged: (crop) =>
                            setState(() => _edit = _edit.copyWith(crop: crop)),
                      ),
                    ),
                  ),
                  _ => const CircularProgressIndicator(),
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.photoEditHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.saveButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs the decode/encode on a worker isolate.
Future<Uint8List?> _applyOffThread(Uint8List bytes, PhotoEdit edit) async {
  if (edit.isIdentity) return bytes;
  return Isolate.run(() => applyPhotoEdit(bytes, edit));
}

/// The picture with a draggable rectangle over it.
///
/// The rectangle lives in fractions of the *displayed* picture, so the
/// same crop means the same thing whatever size the window is. Which is
/// also why the handles work out their new position from the box they are
/// laid out in rather than from the drag's screen coordinates.
class _CropArea extends StatelessWidget {
  const _CropArea({
    required this.image,
    required this.crop,
    required this.onChanged,
  });

  final Widget image;
  final CropRect crop;
  final ValueChanged<CropRect> onChanged;

  /// Big enough for a fingertip, and the same on every corner.
  static const _handle = 44.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final rect = Rect.fromLTWH(
          crop.left * size.width,
          crop.top * size.height,
          crop.width * size.width,
          crop.height * size.height,
        );

        CropRect withDelta(Offset delta, _Corner corner) {
          final dx = delta.dx / size.width;
          final dy = delta.dy / size.height;

          return switch (corner) {
            _Corner.topLeft => CropRect(
              left: crop.left + dx,
              top: crop.top + dy,
              width: crop.width - dx,
              height: crop.height - dy,
            ),
            _Corner.topRight => CropRect(
              left: crop.left,
              top: crop.top + dy,
              width: crop.width + dx,
              height: crop.height - dy,
            ),
            _Corner.bottomLeft => CropRect(
              left: crop.left + dx,
              top: crop.top,
              width: crop.width - dx,
              height: crop.height + dy,
            ),
            _Corner.bottomRight => crop.copyWith(
              width: crop.width + dx,
              height: crop.height + dy,
            ),
          }.normalized;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            image,
            // Everything outside the rectangle, dimmed. Not interactive:
            // a tap there is a miss, not a command.
            IgnorePointer(
              child: CustomPaint(
                painter: _CropPainter(
                  rect: rect,
                  colour: Theme.of(context).colorScheme.surface,
                  outline: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // The body, for moving the whole rectangle.
            Positioned.fromRect(
              rect: rect,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) => onChanged(
                  crop
                      .copyWith(
                        left: crop.left + details.delta.dx / size.width,
                        top: crop.top + details.delta.dy / size.height,
                      )
                      .normalized,
                ),
              ),
            ),
            for (final corner in _Corner.values)
              Positioned(
                left: switch (corner) {
                  _Corner.topLeft ||
                  _Corner.bottomLeft => rect.left - _handle / 2,
                  _ => rect.right - _handle / 2,
                },
                top: switch (corner) {
                  _Corner.topLeft || _Corner.topRight => rect.top - _handle / 2,
                  _ => rect.bottom - _handle / 2,
                },
                width: _handle,
                height: _handle,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) =>
                      onChanged(withDelta(details.delta, corner)),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onPrimary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CropPainter extends CustomPainter {
  _CropPainter({
    required this.rect,
    required this.colour,
    required this.outline,
  });

  final Rect rect;
  final Color colour;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn as one path with an even-odd fill rather than four
    // rectangles: the seams between four would show as hairlines.
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(rect),
    );
    canvas.drawPath(shade, Paint()..color = colour.withValues(alpha: 0.7));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.rect != rect || old.colour != colour || old.outline != outline;
}
