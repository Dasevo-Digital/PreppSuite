import 'dart:async' show unawaited;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart' show HttpResponseError;

import '../../../core/app_database_directory.dart';

/// How an article can be put in front of the reader here.
///
/// A ZIM article is real Wikipedia — stylesheets, tables, maths — so it
/// needs a browser engine, and which one is reachable differs by
/// platform. Every platform has one; only the shape of the window around
/// it changes.
enum ArticleViewer {
  /// Inside the app, through `webview_flutter`.
  panel,

  /// In a window of its own, through `desktop_webview_window`.
  ///
  /// Linux and Windows have no embedded implementation to reach. A window
  /// is a fair trade for the alternative, which is bundling a second
  /// browser and several hundred megabytes with the app.
  window,

  /// Drawn by the app itself, without any engine at all.
  ///
  /// The fallback for the case that used to end in a message and nothing
  /// else: WebKitGTK not installed on Linux, the WebView2 runtime absent
  /// on Windows. Neither can be fetched without a network, which is the
  /// situation this app exists for — so the article is parsed and drawn
  /// here instead. See `article_document.dart`.
  ///
  /// Bundling the engine instead was measured and rejected: WebKitGTK
  /// looks for its helper processes at a path compiled into the library
  /// (`/usr/lib/<arch>/webkit2gtk-4.1`), there is no `WEBKIT_EXEC_PATH`
  /// in a release build and it works the path out neither from `dladdr`
  /// nor from `/proc/self/*` — so a copied library finds nothing. And
  /// Chromium through CEF is a 300 MB download against an app of 31 MB.
  builtIn,

  none,
}

/// What this platform can do.
ArticleViewer get articleViewer =>
    kIsWeb ? ArticleViewer.none : articleViewerFor(defaultTargetPlatform);

/// Split out from [articleViewer] so the mapping can be tested; the
/// platform itself cannot be.
///
/// **Linux draws the article itself** (#421). The window there is
/// WebKitGTK through `desktop_webview_window`, whose `decide-policy`
/// handler only reports a navigation and lets it go on: the app's refusal
/// arrives after WebKit has started loading, so a link, a script or a
/// `<meta http-equiv=refresh>` in a crafted archive could take the page,
/// and what it says, onto the internet before `window.stop()` lands — the
/// CSP does not govern navigation. Until the plugin decides in its native
/// handler, Linux reads with the built-in reader, which loads nothing from
/// anywhere. Windows keeps its window: WebView2 holds the navigation until
/// the app has answered.
ArticleViewer articleViewerFor(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS => ArticleViewer.panel,
  TargetPlatform.windows => ArticleViewer.window,
  TargetPlatform.linux => ArticleViewer.builtIn,
  // Nothing to embed and no window to open: the app draws it itself.
  TargetPlatform.fuchsia => ArticleViewer.builtIn,
};

/// Whether [target] is served by the loopback server behind [origin].
///
/// Split out from the article screen so the rule can be tested; a
/// `WebViewController` cannot be. The port is compared as well as the
/// host, because another app on the device may be serving something else
/// on a different loopback port, and that is no more part of this archive
/// than a site on the internet is.
bool isArchiveUrl(Uri? target, Uri origin) {
  if (target == null) return false;
  return target.scheme == origin.scheme &&
      target.host == origin.host &&
      target.port == origin.port;
}

/// Whether [error] is about the page itself rather than something on it.
///
/// Android reports an HTTP error for every resource a page loads, and its
/// `onHttpError` carries no main-frame flag the way `onWebResourceError`
/// does: one picture missing from the archive answered 404 and replaced
/// the whole article with the error screen, and "Reload" ended the same
/// way (#407). So the request is compared with [document], the page being
/// loaded, without its fragment -- `#Geschichte` is the same page. WebKit
/// reports only the navigation itself and names no request; that one is
/// always the page.
bool isPageHttpError(HttpResponseError error, {required Uri? document}) {
  final requested = error.request?.uri;
  if (requested == null) return true;
  if (document == null) return false;
  return _withoutFragment(requested) == _withoutFragment(document);
}

/// [uri] as a comparable string: no fragment, and the path decoded, so
/// that `%C3%A4` and `ä` are the same page.
String _withoutFragment(Uri uri) {
  final plain = uri.removeFragment();
  String path;
  try {
    path = Uri.decodeFull(plain.path);
  } on ArgumentError {
    path = plain.path;
  }
  return '${plain.scheme}://${plain.host}:${plain.port}$path?${plain.query}';
}

/// Opens [uri] in a browser window of its own.
///
/// False when the system has no engine to open it with. That is a real
/// state rather than a failure: WebView2 ships with Windows 11 but not
/// always with 10, and a Linux desktop without WebKitGTK installed is
/// perfectly ordinary.
Future<bool> openArticleWindow({
  required String title,
  required Uri uri,
}) async {
  try {
    if (!await WebviewWindow.isWebviewAvailable()) return false;

    final window = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: title,
        userDataFolderWindows: await _windowsUserDataFolder(),
      ),
    );
    // The same rule the embedded panel enforces: an archive may contain
    // anything, and a link or a script that leaves it must not take the
    // reader — and what the page says — onto the internet. The window
    // had no such rule at all.
    //
    // On Windows the answer is honoured: WebView2 holds the navigation
    // until this returns. On Linux the plugin only reports it and lets
    // WebKitGTK carry on whatever comes back, so there it is stopped by
    // hand. That is a race the request can win, which is why Linux opens
    // no window at all any more ([articleViewerFor], #421); the stop
    // stays for anything that still gets here.
    window.setOnUrlRequestCallback((url) {
      if (isArchiveUrl(Uri.tryParse(url), uri)) return true;
      if (defaultTargetPlatform == TargetPlatform.linux) {
        unawaited(window.stop());
      }
      return false;
    });
    window.launch(uri.toString());
    return true;
  } on Object {
    // MissingPluginException where the plugin is absent, PlatformException
    // where the engine is. Neither is worth crashing a reading app over.
    return false;
  }
}

/// Where WebView2 may keep its cache.
///
/// It defaults to a folder beside the executable, which is `Program Files`
/// for anything actually installed — and not writable. The failure would
/// only ever show up on an installed copy, never on a developer's.
Future<String> _windowsUserDataFolder() async {
  if (defaultTargetPlatform != TargetPlatform.windows) return '';
  return p.join((await appSupportDirectory()).path, 'webview2');
}
