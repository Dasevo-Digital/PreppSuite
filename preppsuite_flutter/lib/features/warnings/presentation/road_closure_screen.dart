import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/road_closure_client.dart';
import '../application/road_closure_store.dart';

/// What is shut on the Autobahnen this household watches.
///
/// The point is leaving: when a region has to be left, "which way is
/// open" is a more concrete question than any checklist. The Autobahn
/// GmbH publishes closures and its own warnings; this shows them, in its
/// words, for the roads that were named once.
///
/// The interface is per road — there is no "what is shut near me" to ask
/// — which is why the roads are chosen rather than found.
class RoadClosureScreen extends StatefulWidget {
  const RoadClosureScreen({
    super.key,
    this.client,
    this.store = const RoadClosureStore(),
  });

  final RoadClosureClient? client;
  final RoadClosureStore store;

  @override
  State<RoadClosureScreen> createState() => _RoadClosureScreenState();
}

class _RoadClosureScreenState extends State<RoadClosureScreen> {
  late final RoadClosureClient _client = widget.client ?? RoadClosureClient();

  var _roads = <String>[];
  var _events = <RoadEvent>[];
  var _loading = true;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final roads = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _roads = roads;
      _loading = roads.isNotEmpty;
    });
    if (roads.isNotEmpty) await _refresh();
  }

  Future<void> _refresh() async {
    if (_roads.isEmpty) return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    // One road failing must not hide the others, the same rule the
    // warning sources follow. Asked together rather than in turn: one
    // round trip instead of one per road.
    //
    // Failure is recorded as failure and never inferred from an empty
    // list. An open road answers with nothing, and "nothing is shut" and
    // "could not ask" must not look the same — that confusion is the one
    // way this screen could actively mislead somebody.
    final answers = await Future.wait(
      _roads.map((road) async {
        try {
          return await _client.fetchEvents(road);
        } on Object {
          return null;
        }
      }),
    );

    final collected = <RoadEvent>[];
    var answered = 0;
    for (final events in answers) {
      if (events == null) continue;
      answered++;
      collected.addAll(events);
    }

    if (!mounted) return;
    setState(() {
      _events = collected;
      _loading = false;
      _failed = answered == 0;
    });
  }

  Future<void> _choose() async {
    final picked = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => _RoadPicker(client: _client, chosen: _roads),
      ),
    );
    if (picked == null) return;
    await widget.store.save(picked);
    if (!mounted) return;
    setState(() {
      _roads = picked;
      _events = const [];
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roadClosureTitle),
        actions: [
          if (_roads.isNotEmpty)
            IconButton(
              tooltip: l10n.roadClosureRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _refresh,
            ),
        ],
      ),
      body: _roads.isEmpty ? _empty(l10n) : _chosen(l10n),
    );
  }

  Widget _empty(AppLocalizations l10n) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        l10n.roadClosureNoneChosen,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(l10n.roadClosureWhy),
      const SizedBox(height: 16),
      FilledButton(onPressed: _choose, child: Text(l10n.roadClosureChoose)),
      const SizedBox(height: 24),
      Text(
        l10n.roadClosureSource,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _chosen(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final now = [
      for (final event in _events)
        if (event.current) event,
    ];
    final later =
        [
          for (final event in _events)
            if (!event.current) event,
        ]..sort((a, b) {
          final at = a.startsAt;
          final bt = b.startsAt;
          if (at == null || bt == null) return 0;
          return at.compareTo(bt);
        });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_roads.join(' · '), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (_loading && _events.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_failed)
          Text(l10n.roadClosureLoadFailed)
        else ...[
          Text(l10n.roadClosureNow, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (now.isEmpty)
            Text(l10n.roadClosureNothingNow)
          else
            for (final event in now) _EventCard(event: event, l10n: l10n),
          if (later.isNotEmpty) ...[
            const SizedBox(height: 20),
            // Apart from what is standing on the road now: a closure
            // beginning on Friday is worth knowing and is not a reason to
            // turn round today.
            Text(l10n.roadClosureLater, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final event in later.take(10))
              _EventCard(event: event, l10n: l10n),
          ],
        ],
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _choose, child: Text(l10n.roadClosureChange)),
        const SizedBox(height: 16),
        Text(l10n.roadClosureSource, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.l10n});

  final RoadEvent event;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.kind == RoadEventKind.closure
                      ? Icons.block
                      : Icons.warning_amber_outlined,
                  size: 18,
                  color: event.blocked
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // Closures are titled "A2 | Oberhausen - Gladbeck",
                    // but a warning's title is free text and often names
                    // no road at all — "Beseitigung Unfall und Gebrauch
                    // - Sperrung Parallelfahrspur", seen live. Watching
                    // several motorways at once, a card that does not say
                    // which one it is about is useless.
                    event.title.startsWith(event.road)
                        ? event.title
                        : '${event.road} | ${event.title}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (event.direction case final direction?) ...[
              const SizedBox(height: 2),
              Text(direction, style: theme.textTheme.bodySmall),
            ],
            if (event.blocked) ...[
              const SizedBox(height: 4),
              Text(
                l10n.roadClosureBlocked,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (event.startsAt case final start?) ...[
              const SizedBox(height: 4),
              Text(
                l10n.roadClosureFrom(
                  DateFormat.yMd(locale).add_Hm().format(start.toLocal()),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              // The service's own lines, in its own words. Trimmed to
              // four, because some run to a page of construction-phase
              // dates that nobody reads on a phone.
              for (final line in event.description.take(4))
                Text(line, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pick the Autobahnen worth watching.
class _RoadPicker extends StatefulWidget {
  const _RoadPicker({required this.client, required this.chosen});

  final RoadClosureClient client;
  final List<String> chosen;

  @override
  State<_RoadPicker> createState() => _RoadPickerState();
}

class _RoadPickerState extends State<_RoadPicker> {
  var _roads = <String>[];
  late final _chosen = {...widget.chosen};
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<String> roads;
    try {
      roads = await widget.client.fetchRoads();
    } on Object {
      roads = const [];
    }
    if (!mounted) return;
    setState(() {
      _roads = roads;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.roadClosureChoose),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_chosen.toList()..sort()),
            child: Text(l10n.roadClosureDone),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _roads.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.roadClosureLoadFailed),
            )
          : ListView.builder(
              itemCount: _roads.length,
              itemBuilder: (context, index) {
                final road = _roads[index];
                return CheckboxListTile(
                  title: Text(road),
                  value: _chosen.contains(road),
                  onChanged: (on) => setState(() {
                    if (on ?? false) {
                      _chosen.add(road);
                    } else {
                      _chosen.remove(road);
                    }
                  }),
                );
              },
            ),
    );
  }
}
