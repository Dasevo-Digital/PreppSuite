import 'package:flutter/material.dart';

import 'selectable_everywhere.dart';

/// Keeps a protected navigator out of sight, input and semantics while a
/// gate is closed. Its routes survive a relock, but are not built at all
/// before the first successful opening. Public help has its own navigator.
class ProtectedNavigation extends StatefulWidget {
  const ProtectedNavigation({
    super.key,
    required this.child,
    required this.gate,
    this.gateNavigatorKey,
  });

  final Widget child;
  final Widget? gate;
  final GlobalKey<NavigatorState>? gateNavigatorKey;

  @override
  State<ProtectedNavigation> createState() => _ProtectedNavigationState();
}

class _ProtectedNavigationState extends State<ProtectedNavigation> {
  bool _opened = false;
  final _heroes = HeroController();

  @override
  void dispose() {
    _heroes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gate = widget.gate;
    final closed = gate != null;
    if (!closed) _opened = true;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: closed,
          child: ExcludeFocus(
            excluding: closed,
            child: TickerMode(
              enabled: !closed,
              child: _opened ? widget.child : const SizedBox.shrink(),
            ),
          ),
        ),
        if (gate != null)
          SelectableEverywhere(
            child: HeroControllerScope(
              controller: _heroes,
              child: Navigator(
                key: widget.gateNavigatorKey,
                pages: [
                  // No PopScope: the only page of its navigator cannot be
                  // popped anyway, and refusing made system back "handled"
                  // with nothing done (#224).
                  MaterialPage<void>(
                    key: const ValueKey('closed-gate'),
                    child: gate,
                  ),
                ],
                onDidRemovePage: (_) {},
              ),
            ),
          ),
      ],
    );
  }
}
