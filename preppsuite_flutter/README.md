# PreppSuite Flutter

Lokale Vorrats- und Notfallplanung mit Flutter, Riverpod und Drift/SQLite.
Die Anwendung benötigt weder Server noch Konto.

Abhängigkeiten im Workspace-Wurzelverzeichnis installieren:

```bash
flutter pub get
cd preppsuite_flutter
flutter run
flutter test
```

Funktionsumfang und Einrichtung stehen in der [Projekt-README](../README.md),
Architekturregeln in [ARCHITEKTUR.md](../ARCHITEKTUR.md).
Native Speicher- und Webview-Tests laufen in der mobilen CI und lokal mit
`flutter test integration_test/ -d <device>` auf Android oder iOS.
