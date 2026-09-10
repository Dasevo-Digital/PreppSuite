import 'package:flutter/widgets.dart';

/// Calls [onPressure] when the system says memory is running short.
///
/// The one warning a phone gives before it starts killing applications.
/// What this app holds that is worth dropping is the decoded map tiles and
/// the open archive handles — see `archive_memory_limits.dart` — and both
/// can be rebuilt from disk, which makes them exactly the right thing to
/// let go of when asked.
///
/// [dispose] has to be called, or the observer outlives whatever installed
/// it and keeps that object alive with it.
class MemoryPressureListener extends WidgetsBindingObserver {
  MemoryPressureListener(this.onPressure) {
    WidgetsBinding.instance.addObserver(this);
  }

  final VoidCallback onPressure;

  @override
  void didHaveMemoryPressure() => onPressure();

  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
