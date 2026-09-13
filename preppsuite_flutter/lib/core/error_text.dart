import 'dart:async' show TimeoutException;
import 'dart:io';

import 'package:drift/drift.dart'
    show DriftWrappedException, InvalidDataException;
import 'package:flutter/services.dart' show PlatformException;
import 'package:sqlite3/common.dart' show SqliteException;

import '../features/downloads/application/archive_downloader.dart'
    show DownloadException;
import '../features/knowledge/application/kiwix_catalogue.dart'
    show KiwixCatalogueException;
import '../features/knowledge/application/xapian_index.dart'
    show XapianException;
import '../features/knowledge/application/zim_archive.dart' show ZimException;
import '../features/maps/application/pmtiles_archive.dart'
    show PmTilesException;
import '../features/maps/application/place_search.dart'
    show PlaceSearchException;
import '../features/maps/application/tile_source.dart' show TileSourceException;
import '../features/shelters/application/overpass_shelter_client.dart'
    show OverpassException;
import '../l10n/generated/app_localizations.dart';

/// What to put on the screen when something failed.
///
/// The app used to show `error.toString()` in sixteen places. That reads
/// as "Es ist ein Fehler aufgetreten: SqliteException(11): database disk
/// image is malformed" — English, technical, and in an app that gets
/// opened when something has already gone wrong. What somebody needs
/// there is what happened and what they can do about it.
///
/// The unknown case keeps the technical text on purpose. Replacing every
/// failure with a soothing sentence would leave nothing to report and
/// nothing to search for; the ones below are named because they are the
/// ones that actually happen.
String describeError(AppLocalizations l10n, Object error) {
  return switch (error) {
    // No network. By far the most common of these, and the only one where
    // trying again is the right advice.
    SocketException() ||
    HttpException() ||
    TimeoutException() => l10n.errorNoConnection,

    // A file that was there when it was picked and is not now: an unplugged
    // disk, a folder the user tidied, a permission that did not survive.
    PmTilesException() ||
    ZimException() ||
    XapianException() => l10n.errorArchiveUnreadable,

    FileSystemException() => l10n.errorFileUnreadable,

    DownloadException() => l10n.errorDownloadFailed,

    // The services behind the map and the library are somebody else's.
    TileSourceException() ||
    PlaceSearchException() ||
    OverpassException() ||
    KiwixCatalogueException() => l10n.errorServiceUnavailable,

    // Drift wraps whatever the underlying database threw. The raw type is
    // named as well because one path does not go through that wrapper:
    // a failure while the database is being opened, i.e. a migration.
    // Without this, an interrupted migration put SQLite's own words on
    // the screen -- "duplicate column name: local_contact_point, SQL
    // logic error (code 1)", followed by the ALTER TABLE statement.
    DriftWrappedException() ||
    InvalidDataException() ||
    SqliteException() => l10n.errorDatabase,

    // Camera, location, notifications, the file picker — everything the
    // system can refuse.
    PlatformException() => l10n.errorPlatformRefused,

    _ => l10n.errorGeneric(error.toString()),
  };
}
