import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const serverUrlPrefsKey = 'serverUrl';

/// Turns what someone types into an address the client can use, or null if
/// it cannot be made into one.
///
/// People write down a server the short way — `192.168.1.5:8080`,
/// `preppsuite.example.com`, with or without a trailing slash. Rejecting
/// those and demanding a full URL would be pedantry; the difference is
/// mechanical, so it is done here.
///
/// Two decisions worth stating:
///
/// * A missing scheme becomes `https://`, except for plain-IP and
///   `localhost` addresses, which become `http://`. Home servers are
///   usually reached by IP without a certificate, while a hostname on the
///   open internet should not be silently downgraded to an unencrypted
///   connection.
/// * The result always ends in a slash. Serverpod builds endpoint paths by
///   appending to this string, so a missing one produces requests to
///   `…example.cominventory`.
String? normalizeServerUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.contains(RegExp(r'\s'))) return null;

  // A colon means either a scheme or a port, and the two need telling
  // apart: "localhost:8080" is a host with a port, "mailto:someone@…" is a
  // scheme. Digits after the colon settle it. Without this check a scheme
  // written without slashes would get "https://" pasted in front of it and
  // parse into something that looks valid but can never connect.
  final schemeMatch = RegExp(
    r'^([a-zA-Z][a-zA-Z0-9+.-]*):',
  ).firstMatch(trimmed);
  if (schemeMatch != null) {
    final afterColon = trimmed.substring(schemeMatch.end);
    final isPort = RegExp(r'^\d').hasMatch(afterColon);
    if (!isPort &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://')) {
      return null;
    }
  }

  final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
  final withScheme = hasScheme
      ? trimmed
      : '${_looksLocal(trimmed) ? 'http' : 'https'}://$trimmed';

  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;

  final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
  return uri.replace(path: path).toString();
}

/// Whether an address points at the same machine or a private network, and
/// therefore has no certificate to speak of.
bool _looksLocal(String input) {
  final host = input.split('/').first.split(':').first.toLowerCase();
  if (host == 'localhost' || host.endsWith('.local')) return true;
  return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
}

/// The server this app talks to.
///
/// Falls back to whatever was compiled in (`--dart-define=SERVER_URL`, or
/// `assets/config.json`, which is `localhost` by default). Storing it lets
/// someone install a released build and point it at their own server,
/// instead of having to build the app themselves just to change one
/// string — which was the case before.
class ServerUrlController extends Notifier<String> {
  @override
  String build() {
    unawaited(_loadStored());
    return compiledDefault;
  }

  /// Set once at startup from `main`, before the app runs.
  static String compiledDefault = '';

  Future<void> _loadStored() async {
    final prefs = await SharedPreferences.getInstance();
    // See LocaleOverrideController for why this guard is needed after an
    // async gap.
    if (!ref.mounted) return;

    final stored = prefs.getString(serverUrlPrefsKey);
    if (stored != null && stored.isNotEmpty) state = stored;
  }

  /// Stores [url] as typed-and-normalized. Returns false if it could not
  /// be read as an address, in which case nothing is stored.
  Future<bool> setServerUrl(String url) async {
    final normalized = normalizeServerUrl(url);
    if (normalized == null) return false;

    state = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverUrlPrefsKey, normalized);
    return true;
  }
}

final serverUrlProvider = NotifierProvider<ServerUrlController, String>(
  ServerUrlController.new,
);
