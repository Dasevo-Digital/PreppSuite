import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/local_discovery.dart';
import 'qr_receive_screen.dart';

/// Shows anonymous local transfer beacons and keeps the final pairing step
/// physical: selecting a device opens the QR scanner, it never connects by
/// itself.
class LocalDevicesScreen extends StatefulWidget {
  const LocalDevicesScreen({super.key, required this.householdId});

  final String householdId;

  @override
  State<LocalDevicesScreen> createState() => _LocalDevicesScreenState();
}

class _LocalDevicesScreenState extends State<LocalDevicesScreen> {
  LocalTransferDiscovery? _discovery;
  StreamSubscription<List<LocalTransferPresence>>? _subscription;
  List<LocalTransferPresence> _devices = const [];
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final discovery = await LocalTransferDiscovery.start();
      if (!mounted) {
        await discovery.dispose();
        return;
      }
      _subscription = discovery.devices.listen((devices) {
        if (mounted) setState(() => _devices = devices);
      });
      setState(() => _discovery = discovery);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_discovery?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferNearbyTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.transferNearbyHint),
            const SizedBox(height: 16),
            Expanded(
              child: _failed
                  ? Center(child: Text(l10n.transferNearbyUnavailable))
                  : _discovery == null
                  ? const Center(child: CircularProgressIndicator())
                  : _devices.isEmpty
                  ? Center(child: Text(l10n.transferNearbyEmpty))
                  : ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.devices_other_outlined),
                          title: Text(l10n.transferNearbyDevice),
                          subtitle: Text(l10n.transferNearbyScanHint),
                          trailing: const Icon(Icons.qr_code_scanner),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QrReceiveScreen(
                                householdId: widget.householdId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
