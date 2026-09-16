import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../sharing/application/shared_folder_store.dart';
import '../../sharing/application/snapshot_exchange.dart';
import '../application/local_handover.dart';
import '../application/local_discovery.dart';
import '../application/qr_chain.dart';
import 'qr_code_view.dart';

/// Offers the household to another device, by whichever road is open.
///
/// Two roads, one screen, because to the person holding the phone it is
/// one job. Which one is used is decided by whether this device is on a
/// network at all, and it can be overridden — a network that exists is
/// not always a network the other device is on.
///
///   * **Over the network.** One small code holding an address and a
///     fresh key. The whole household crosses in one request, both ways,
///     in under a second. See `local_handover.dart`.
///   * **A run of pictures.** Needs nothing whatsoever. The frames loop
///     for ever rather than playing once and stopping: there is no back
///     channel, so looping is what makes a missed frame harmless — it
///     comes round again a few seconds later. Somebody holding a phone up
///     does not have to aim well, only to keep holding it.
class QrSendScreen extends ConsumerStatefulWidget {
  const QrSendScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<QrSendScreen> createState() => _QrSendScreenState();
}

class _QrSendScreenState extends ConsumerState<QrSendScreen> {
  /// Null until it is known whether this device is on a network at all.
  LocalHandoverHost? _host;
  var _overNetwork = true;
  var _networkTried = false;
  String? _handoverResult;
  StreamSubscription<LocalHandoverResult>? _watching;
  LocalTransferBroadcaster? _broadcaster;

  /// How long one frame stays up.
  ///
  /// Adjustable, and adjustable by the person rather than guessed at,
  /// because the right answer is not a constant: it depends on the
  /// camera, the light and the screen. Too fast and the other device
  /// misses most of a pass; too slow and a long household takes a
  /// minute. The middle step is the starting point, not a measured
  /// optimum -- whoever is holding the phone can see whether frames are
  /// landing and change it.
  static const _steps = [
    Duration(milliseconds: 900),
    Duration(milliseconds: 500),
    Duration(milliseconds: 300),
  ];
  var _step = 1;

  List<String>? _frames;
  Object? _failure;
  var _at = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _openNetwork();
    _build();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _watching?.cancel();
    _broadcaster?.dispose();
    // Fire and forget: the socket is going away with the screen and
    // nothing is waiting on the answer.
    unawaited(_host?.stop() ?? Future<void>.value());
    super.dispose();
  }

  Future<void> _openNetwork() async {
    try {
      final host = await LocalHandoverHost.start(
        db: ref.read(appDatabaseProvider),
        deviceId: await const SharedFolderStore().deviceId(),
        householdId: widget.householdId,
      );
      if (!mounted) {
        await host.stop();
        return;
      }
      _watching = host.handovers.listen((result) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _handoverResult = result.received == 0
              ? l10n.transferHandoverNothing
              : l10n.transferHandoverDone(result.received);
        });
      });
      final broadcaster = await LocalTransferBroadcaster.start();
      if (!mounted) {
        broadcaster.dispose();
        await host.stop();
        return;
      }
      setState(() {
        _host = host;
        _broadcaster = broadcaster;
        _networkTried = true;
      });
    } on Object {
      // No network, or the port could not be opened. The pictures still
      // work, and that is the whole point of having both.
      if (!mounted) return;
      setState(() {
        _networkTried = true;
        _overNetwork = false;
      });
    }
  }

  Future<void> _build() async {
    try {
      final snapshot = await readHouseholdSnapshot(
        ref.read(appDatabaseProvider),
        deviceId: await const SharedFolderStore().deviceId(),
        householdId: widget.householdId,
      );
      final frames = qrChainFrames(
        Uint8List.fromList(utf8.encode(snapshot.encode())),
      );
      if (!mounted) return;
      setState(() => _frames = frames);
      _start();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _failure = error);
    }
  }

  void _start() {
    _timer?.cancel();
    final frames = _frames;
    if (frames == null || frames.length < 2) return;
    _timer = Timer.periodic(_steps[_step], (_) {
      if (!mounted) return;
      setState(() => _at = (_at + 1) % frames.length);
    });
  }

  void _changeSpeed(int by) {
    setState(() => _step = (_step + by).clamp(0, _steps.length - 1));
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final host = _host;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferSendTitle)),
      body: switch (this) {
        _ when !_networkTried && _frames == null && _failure == null =>
          const Center(child: CircularProgressIndicator()),
        _ when _overNetwork && host != null => _OverNetwork(
          host: host,
          l10n: l10n,
          result: _handoverResult,
          onUseChain: () => setState(() => _overNetwork = false),
        ),
        _ => _Chain(
          frames: _frames,
          failure: _failure,
          at: _at,
          l10n: l10n,
          onSlower: _step > 0 ? () => _changeSpeed(-1) : null,
          onFaster: _step < _steps.length - 1 ? () => _changeSpeed(1) : null,
          onUseNetwork: host == null
              ? null
              : () => setState(() => _overNetwork = true),
          noNetwork: host == null,
        ),
      },
    );
  }
}

/// The fast road: one code holding an address and a key.
class _OverNetwork extends StatelessWidget {
  const _OverNetwork({
    required this.host,
    required this.l10n,
    required this.result,
    required this.onUseChain,
  });

  final LocalHandoverHost host;
  final AppLocalizations l10n;
  final String? result;
  final VoidCallback onUseChain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              l10n.transferSendOverNetwork,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.transferSendOverNetworkHint,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(
              child: QrCodeView(
                data: host.invitation.encode(),
                size: (constraints.biggest.shortestSide - 32).clamp(
                  200.0,
                  420.0,
                ),
                semanticLabel: l10n.transferSendOverNetwork,
              ),
            ),
            const SizedBox(height: 16),
            if (result case final done?)
              Text(
                done,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: Text(l10n.transferSendWaiting)),
                ],
              ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onUseChain,
              icon: const Icon(Icons.qr_code_2),
              label: Text(l10n.transferUseChain),
            ),
          ],
        ),
      ),
    );
  }
}

/// The road that needs nothing: a run of pictures.
class _Chain extends StatelessWidget {
  const _Chain({
    required this.frames,
    required this.failure,
    required this.at,
    required this.l10n,
    required this.onSlower,
    required this.onFaster,
    required this.onUseNetwork,
    required this.noNetwork,
  });

  final List<String>? frames;
  final Object? failure;
  final int at;
  final AppLocalizations l10n;
  final VoidCallback? onSlower;
  final VoidCallback? onFaster;
  final VoidCallback? onUseNetwork;
  final bool noNetwork;

  @override
  Widget build(BuildContext context) {
    if (failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.transferSendNothing, textAlign: TextAlign.center),
        ),
      );
    }
    final frames = this.frames;
    if (frames == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _Frames(
      frames: frames,
      at: at,
      l10n: l10n,
      onSlower: onSlower,
      onFaster: onFaster,
      onUseNetwork: onUseNetwork,
      noNetwork: noNetwork,
    );
  }
}

class _Frames extends StatelessWidget {
  const _Frames({
    required this.frames,
    required this.at,
    required this.l10n,
    required this.onSlower,
    required this.onFaster,
    required this.onUseNetwork,
    required this.noNetwork,
  });

  final List<String> frames;
  final int at;
  final AppLocalizations l10n;
  final VoidCallback? onSlower;
  final VoidCallback? onFaster;
  final VoidCallback? onUseNetwork;
  final bool noNetwork;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // As big as the screen allows: every pixel of module size is a
        // metre of distance the other camera can stand back.
        final side = constraints.biggest.shortestSide - 32;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (noNetwork) ...[
                Text(
                  l10n.transferSendNoNetwork,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              Text(l10n.transferSendChainHint, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Center(
                child: QrCodeView(
                  data: frames[at],
                  size: side.clamp(200.0, 520.0),
                  semanticLabel: l10n.transferFrameOf(at + 1, frames.length),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.transferFrameOf(at + 1, frames.length),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (at + 1) / frames.length),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onSlower,
                    icon: const Icon(Icons.slow_motion_video),
                    label: Text(l10n.transferSlower),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onFaster,
                    icon: const Icon(Icons.fast_forward),
                    label: Text(l10n.transferFaster),
                  ),
                ],
              ),
              if (onUseNetwork case final back?) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: back,
                  icon: const Icon(Icons.wifi),
                  label: Text(l10n.transferUseNetwork),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
