import 'package:flutter/widgets.dart';

/// Keeps navigation state while allowing expensive child resources to stop.
class FeatureActivity extends InheritedWidget {
  const FeatureActivity({
    super.key,
    required this.active,
    required super.child,
  });
  final bool active;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FeatureActivity>()?.active ??
      true;
  @override
  bool updateShouldNotify(FeatureActivity oldWidget) =>
      active != oldWidget.active;
}
