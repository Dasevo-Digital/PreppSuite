import 'dart:async';

import 'package:flutter/material.dart';

import '../features/first_aid/presentation/compression_pacer_screen.dart';
import '../features/first_aid/presentation/first_aid_screen.dart';
import '../features/home/presentation/distress_signal_screen.dart';
import '../features/home/presentation/radio_emergency_screen.dart';
import '../l10n/generated/app_localizations.dart';
import 'phone_call.dart';

/// The help that needs nothing the household stored (#136, #137).
///
/// Every screen in front of the household -- the data key that cannot be
/// read, the app lock, a database that does not open -- used to be a dead
/// end. Each of them is a moment in which the app may be all somebody has
/// to hand, and none of what is here depends on what they are waiting
/// for: the emergency numbers, the first-aid guides and the compression
/// rhythm are part of the app, the distress signal and the radio
/// frequencies too. Nothing private is shown, so a locked app may show
/// it as freely as a locked phone shows its emergency call.
class EmergencyAccessScreen extends StatelessWidget {
  const EmergencyAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyAccessTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              minimumSize: const Size.fromHeight(64),
              textStyle: theme.textTheme.titleLarge,
            ),
            onPressed: () => callNumber(context, '112'),
            icon: const Icon(Icons.call),
            label: Text(l10n.emergencyAccessCall112),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => callNumber(context, '110'),
            icon: const Icon(Icons.local_police_outlined),
            label: Text(l10n.emergencyAccessCall110),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: Text(l10n.firstAidTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(const FirstAidScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: Text(l10n.pacerTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(const CompressionPacerScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.flashlight_on_outlined),
                  title: Text(l10n.distressTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(const DistressSignalScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.radio_outlined),
                  title: Text(l10n.radioEmergencyTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(const RadioEmergencyScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.emergencyAccessNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// The way into [EmergencyAccessScreen] from a screen that holds the app.
class EmergencyAccessButton extends StatelessWidget {
  const EmergencyAccessButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error),
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EmergencyAccessScreen()),
      ),
      icon: const Icon(Icons.emergency_outlined),
      label: Text(l10n.emergencyAccessButton),
    );
  }
}

/// A spinner that offers the emergency screen once it has turned for a
/// while.
///
/// The household loads in a moment, and a red button flashing past at
/// every start would be noise. A load that hangs -- a disk that does not
/// answer, a database that takes the lock and keeps it -- must not hold
/// the way to 112 behind it.
class LoadingWithEmergencyAccess extends StatefulWidget {
  const LoadingWithEmergencyAccess({
    super.key,
    this.after = const Duration(seconds: 4),
  });

  final Duration after;

  @override
  State<LoadingWithEmergencyAccess> createState() =>
      _LoadingWithEmergencyAccessState();
}

class _LoadingWithEmergencyAccessState
    extends State<LoadingWithEmergencyAccess> {
  Timer? _timer;
  var _offer = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.after, () {
      if (mounted) setState(() => _offer = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (_offer) ...[
                const SizedBox(height: 32),
                const EmergencyAccessButton(),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
