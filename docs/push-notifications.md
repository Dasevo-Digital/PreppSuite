# Push-Benachrichtigungen (FCM / APNs)

Warnungen erreichen die App bisher nur, solange sie läuft: `SyncService`
zieht neue Warnungen, `NotificationService` zeigt sie lokal an. Ein Handy in
der Hosentasche bleibt damit nachts still — genau dann, wenn eine
Zivilschutzwarnung zählt.

Dieses Dokument beschreibt den Server- und App-Anteil, der das ändert, und
was an Zugangsdaten dafür nötig ist.

## Architektur

Beide Plattformen laufen über **Firebase Cloud Messaging (FCM HTTP v1)**.
Für iOS leitet Firebase an APNs weiter, mit dem APNs-Schlüssel, der im
Firebase-Projekt hinterlegt ist. Der Server hat dadurch **einen** Zugang und
**einen** Sendeweg statt zwei.

```
WarningPollFutureCall  (alle 15 min)
  └─ WarningNormalizer.upsertBbk / upsertMeteoAlarm
       └─ liefert die meldenswerten Warnungen zurück
            └─ WarningPushNotifier
                 ├─ isWarningRelevant(...)   ← dieselbe Regel wie beim Pull
                 ├─ PushDevice-Auswahl je Haushalt
                 └─ FcmSender → FCM → Android / APNs → iOS
```

Die Nutzlast muss trotz eines Sendewegs pro Plattform ausformuliert werden:
Android braucht eine `channel_id`, die die App selbst angelegt hat (sonst
verwirft Android 8+ die Meldung kommentarlos), APNs zeigt nur an, was unter
`aps` steht. `buildFcmMessage` erledigt beides, `fcm_sender_test` hält es
fest.

## Was gepusht wird — und was nicht

Bewusst zurückhaltend, weil eine Benachrichtigung, die man wegwischt, dem
Zweck des ganzen Kanals schadet:

- **Nur neue oder verschärfte Warnungen.** Die Quellen geben Warnungen
  ständig mit korrigiertem Text neu heraus; nur ein tatsächlich neuer
  Eintrag oder eine erhöhte Stufe zählt (`WarningNormalizer._upsert`).
- **Erst ab Stufe `moderate`.** Dieselbe Schwelle, die die App auf ihre
  lokalen Benachrichtigungen anwendet.
- **Bereits abgelaufene Warnungen** gehen nicht raus.
- **Höchstens drei pro Gerät und Durchlauf** (`maxPerDevicePerRun`). Der
  erste Poll einer leeren Datenbank legt sämtliche gerade aktiven Warnungen
  des Landes an — alle „neu“. Ohne Deckel bekäme ein registriertes Gerät
  dutzende Meldungen am Stück und die Funktion wäre danach dauerhaft aus.
  Sortiert wird nach Stufe, damit im Zweifel das Wichtige durchkommt.

## Gerätetoken

`PushDevice` ist bewusst **nicht** Teil der generischen Push/Pull-Sync: Ein
Token gehört zu genau einem Gerät, ist auf einem zweiten nutzlos und darf
dort nie landen. Eindeutigkeit hängt am Token, nicht am Benutzer — Tokens
rotieren bei Neuinstallation und Geräteumzug, und dasselbe Token unter einem
anderen Konto wird verschoben statt dupliziert.

Die App gleicht bei jedem Start und bei jeder Änderung des Schalters ab
(`PushRegistrationService.reconcile`). Das ist idempotent statt An/Aus,
damit eine Abmeldung, die offline scheiterte, beim nächsten Start
nachgeholt wird. Beim Abmelden wird zuerst der Token widerrufen, dann die
Sitzung beendet — andersherum fehlte danach das Token, um es noch zu sagen.

Lehnt FCM ein Token ab (`UNREGISTERED` / `INVALID_ARGUMENT`), wird die Zeile
gelöscht. Alles andere — Quota, 5xx, ein abgelaufener Schlüssel — ist
vorübergehend und lässt das Gerät stehen; sonst würde eine Störung beim
Anbieter reihenweise Leute stillschweigend abmelden.

## Einrichtung

### 1. Firebase-Projekt

<https://console.firebase.google.com> → Projekt anlegen (kostenlos, der
Spark-Plan reicht; FCM hat keine Kosten). Google Analytics kann aus bleiben.

### 2. Apps registrieren

Im Projekt zwei Apps anlegen:

| Plattform | Kennung | Ergebnis |
| --- | --- | --- |
| Android | `de.status403.preppsuite` | `google-services.json` |
| iOS | `de.status403.preppsuite` | `GoogleService-Info.plist` |

Die Dateien gehören nach `preppsuite_flutter/android/app/` bzw.
`preppsuite_flutter/ios/Runner/`. Beide enthalten keine Geheimnisse im
engeren Sinn (sie stecken in jeder ausgelieferten App), sind aber
projektgebunden.

### 3. APNs-Schlüssel (nur iOS)

<https://developer.apple.com/account> → Certificates, Identifiers &
Profiles → Keys → **+** → „Apple Push Notifications service (APNs)“ →
herunterladen. Die `.p8`-Datei gibt es **genau einmal**; dazu Key-ID und
Team-ID notieren. Hochladen unter Firebase → Projekteinstellungen → Cloud
Messaging → Apple app configuration.

Setzt das kostenpflichtige Apple Developer Program voraus (99 €/Jahr).

### 4. Server-Zugangsdaten

Firebase → Projekteinstellungen → Dienstkonten → „Neuen privaten Schlüssel
generieren“. Es kommt eine JSON-Datei heraus. **Die ist ein echtes
Geheimnis** — wer sie hat, kann im Namen deines Projekts Nachrichten an
alle registrierten Geräte schicken.

Der Server sucht sie an zwei Stellen, in dieser Reihenfolge:

**a) Passwort `firebaseServiceAccount`** — in
`preppsuite_server/config/passwords.yaml` (nicht unter Versionskontrolle),
als *eine* Zeile, weil YAML sonst über die Zeilenumbrüche stolpert:

```yaml
shared:
  firebaseServiceAccount: '{"type":"service_account","project_id":"…"}'
```

Einzeilig machen mit `jq -c . dein-schluessel.json`. Einfache
Anführungszeichen sind hier richtig: YAML lässt darin Backslashes in Ruhe,
und die `\n` im `private_key` müssen den JSON-Parser unverändert erreichen.

Alternativ per Umgebungsvariable `PREPPSUITE_FIREBASE_SERVICE_ACCOUNT` —
der Weg für Docker. Achtung: Serverpod liest Umgebungsvariablen **nicht**
von allein als Passwörter; jede muss in `server.dart` über
`pod.loadCustomPasswords` angemeldet werden. Für diesen Schlüssel ist das
bereits eingetragen.

**b) Datei `preppsuite_server/config/firebase_service_account_key.json`** —
einfach die heruntergeladene Datei dorthin legen, fertig. Nichts umformen,
nichts eintragen. Der Pfad steht schon in `.gitignore`.

Der Passworteintrag gewinnt über die Datei, damit eine bewusst gesetzte
Umgebungsvariable nicht von einer vergessenen Datei im Container-Image
überstimmt wird.

Die Projekt-ID liest der Server aus dem Schlüssel selbst; es gibt nichts
Zweites zu konfigurieren, das abweichen könnte.

**Ohne beides startet der Server normal und Push bleibt aus.** Das ist der
Normalzustand einer frischen Installation, kein Fehler.

### 5. App-Anteil

Bis die Dateien aus Schritt 2 vorliegen, ist `firebase_messaging` bewusst
**nicht** als Abhängigkeit eingetragen: Das Gradle-Plugin von Firebase
bricht den Android-Build ohne `google-services.json` ab. Stattdessen gibt es
`PushTokenSource` als Naht — `UnavailablePushTokenSource` meldet „nicht
verfügbar“, und die App verhält sich exakt wie vorher.

Wenn die Dateien da sind, bleibt zu tun:

1. `firebase_core` und `firebase_messaging` in `pubspec.yaml`
2. `com.google.gms.google-services` in `android/settings.gradle.kts` und
   `android/app/build.gradle.kts`
3. `Push Notifications` und `Background Modes → Remote notifications` als
   Capabilities in Xcode
4. Eine `FirebasePushTokenSource` als zweite Implementierung von
   `PushTokenSource`, eingehängt über `pushTokenSourceProvider`

Alles darüber — Registrierung, Widerruf, Tokenrotation, Abmeldung — steht
und ist getestet.

## Datenschutz

Der Weg über FCM bedeutet, dass Google Zeitpunkt und Zielgerät jeder
Warnmeldung sieht. Der Inhalt ist eine öffentliche Zivilschutzwarnung, also
nichts Vertrauliches, aber das Zustellmuster selbst ist ein Datum. Wer das
für eine selbst gehostete Installation nicht will, hat zwei Möglichkeiten:

- **Nur iOS über APNs direkt.** `PushSender` ist genau dafür ein Interface;
  eine zweite Implementierung mit HTTP/2 und ES256-signiertem JWT umgeht
  Firebase für iOS vollständig. Für Android gibt es keine entsprechende
  Alternative, die auf Standardgeräten funktioniert.
- **Gar kein Push.** Ohne `firebaseServiceAccount` bleibt es beim bisherigen
  Verhalten: Warnungen erscheinen, sobald die App läuft.
