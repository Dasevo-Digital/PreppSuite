import 'package:flutter/widgets.dart';

class MemoryPressureListener extends WidgetsBindingObserver {
  MemoryPressureListener(this.onPressure) {
    WidgetsBinding.instance.addObserver(this);
  }
  final VoidCallback onPressure;
  @override
  void didHaveMemoryPressure() => onPressure();
  void dispose() => WidgetsBinding.instance.removeObserver(this);
}
