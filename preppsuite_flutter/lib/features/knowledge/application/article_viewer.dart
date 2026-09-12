import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

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

  none,
}

/// What this platform can do.
ArticleViewer get articleViewer =>
    kIsWeb ? ArticleViewer.none : articleViewerFor(defaultTargetPlatform);

/// Split out from [articleViewer] so the mapping can be tested; the
/// platform itself cannot be.
ArticleViewer articleViewerFor(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS => ArticleViewer.panel,
  TargetPlatform.linux || TargetPlatform.windows => ArticleViewer.window,
  TargetPlatform.fuchsia => ArticleViewer.none,
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
