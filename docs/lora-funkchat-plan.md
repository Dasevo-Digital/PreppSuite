# Funkchat über LoRa — ein Plan

Noch nichts davon ist gebaut. Dieses Dokument hält fest, wie es aussehen
müsste, was vorher zu messen ist und was ausdrücklich nicht gebaut wird.

## Was es werden soll

Kurznachrichten an bestimmte Menschen **außerhalb des Haushalts** —
Eltern, Geschwister, Kinder in der Nachbarstadt — ohne Mobilfunk, ohne
Internet, ohne Anbieter dazwischen.

Nicht: den Haushalt abgleichen. Dafür gibt es den gemeinsamen Ordner, das
örtliche Netz und die Bilderfolge — siehe
[`ohne-netz-uebertragen.md`](ohne-netz-uebertragen.md). Die Rechnung dazu steht
weiter unten unter „Was nicht gebaut wird", weil sie sich hartnäckig
aufdrängt und jedes Mal dasselbe Ergebnis hat.

## Warum das die richtige Frage ist

Die App erklärt auf dem Notfunk-Bildschirm schon PMR446 und Freenet. Das
sind **Sprechfunk**-Bänder: Man hört jemanden oder man hört ihn nicht, und
beide müssen im selben Moment am Gerät sein.

LoRa ist das Datengegenstück dazu, und es löst genau die zwei Dinge, an
denen Sprechfunk scheitert:

- **Es wartet.** Eine Nachricht wird zugestellt, wenn die Gegenstelle
  wieder da ist. Niemand muss auf Empfang sitzen.
- **Es wird weitergereicht.** Ein Knoten auf einem Dach zwischen euch
  überbrückt die Strecke, für die zwei Handgeräte zu schwach sind.

Und es liegt in derselben rechtlichen Schublade wie PMR446: der
SRD-Allgemeinzuteilung **Vfg. 91/2025**. Keine Lizenz, keine Prüfung, kein
Rufzeichen. In Deutschland läuft es üblicherweise im Bereich
**869,4–869,65 MHz**.

## Die erste Entscheidung: welches Netz

Es gibt zwei, sie sind nicht kompatibel, und für diesen Zweck sind sie
nicht gleich gut.

| | Meshtastic | MeshCore |
|---|---|---|
| Weiterreichen | jeder Knoten flutet, max. 3 Sprünge | eigene Repeater, gelernte Pfade, bis 64 Sprünge |
| Direktnachricht | flutet wie alles andere | gelernter Pfad, Quittung mit Sprungliste |
| Verschlüsselung | Kanalschlüssel, DMs mit Schlüsselpaar | Kanalschlüssel, DMs mit Schlüsselpaar |
| Anbindung für Apps | Protobuf über BLE, USB und **TCP:4403** | Binärrahmen über BLE, USB und WLAN |
| Nachrichtenlänge | 233 Byte | 133 Zeichen |

**Für „an eine bestimmte Person" ist MeshCore das passendere.** Es ist
genau dafür entworfen: Die erste Nachricht sucht den Weg, die Quittung
bringt ihn zurück, alle weiteren gehen gezielt statt durch Fluten. Die
Hamburger Gruppe berichtet **70–80 % Zustellung über sieben bis acht
Sprünge**, Einzelstrecken bis 101 km, und eine bestätigte Verbindung
Hamburg–Nürnberg über 13–16 Sprünge.

Meshtastic hat die größere App-Landschaft und einen Vorteil, der hier
wenig hilft: Es kommt ohne jede Infrastruktur aus, weil jedes Gerät
weiterreicht. Das ist stark für eine Wandergruppe und schwach für „meine
Mutter, zwölf Kilometer weiter".

**Das ist eine Empfehlung, keine Messung.** Die Knotenzahlen und
Zuverlässigkeitsangaben stammen von den Gemeinschaftsseiten der Netze
selbst. Deshalb der nächste Abschnitt.

## Schritt 0: messen, nicht bauen

Vor der ersten Zeile Code. Das ist kein Softwareprojekt, sondern ein
Versuch für unter 100 Euro, und er entscheidet, ob sich das Übrige lohnt.

1. **Zwei Geräte kaufen**, eines für hier, eines für die Gegenstelle. Ein
   Board mit LoRa für 869 MHz kostet 20–25 Euro.
2. **Nachsehen, was am eigenen Ort überhaupt da ist.** Beide Netze haben
   öffentliche Karten. Ohne Knoten dazwischen ist die Reichweite die
   nackte Funkstrecke, und die ist in der Stadt schnell zu Ende.
3. **Eine Woche lang echte Nachrichten schicken** und mitschreiben, wie
   viele ankommen und wie lange sie brauchen.

Wenn dabei herauskommt, dass zwischen hier und den Verwandten kein Netz
steht, ist das Ergebnis nicht „Projekt gescheitert", sondern eine andere
Aufgabe: einen Knoten auf ein Dach zu bekommen. Auch das ist eine
Antwort, und die App kann sie nicht liefern.

**Erst danach wird gebaut.** Eine Chat-Oberfläche für ein Netz, das am
eigenen Ort nicht existiert, ist eine schön gemachte Enttäuschung.

## Was die App beiträgt

Beide Netze haben eigene Apps, die besser chatten als PreppSuite es je
tun wird. Die Frage ist also nicht „noch ein Chat", sondern: **Was kann
ein Funkchat _in dieser App_, was er daneben nicht kann?**

Vier Dinge, und sie sind der eigentliche Grund für das Ganze:

1. **Warnungen weiterreichen.** Die App hat BBK- und MeteoAlarm-Warnungen.
   Ein Gerät mit Netz kann eine Warnung gekürzt ins Funknetz geben —
   Ereignis, Gebiet, Stufe — und Haushalte ohne Netz erreichen. Das passt
   in ein Paket und ist der Auftrag dieser App.
2. **Standorte auf der eigenen Karte.** Ein empfangener Standort landet
   auf der **heruntergeladenen** Karte, nicht in einer Kachel aus dem Netz.
3. **Zusammenhang.** „Wir sind am Treffpunkt" ist in einer App, die den
   Treffpunkt kennt, eine andere Nachricht als in einem leeren Chatfenster.
4. **Vorlagen statt Tippen.** 133 Zeichen auf einem Telefon im Regen sind
   kein Chat. Die App kennt die Lage und kann fertige Sätze anbieten.

## Der Bauplan

### Stufe 1 — Lesen

Verbinden und anzeigen, sonst nichts. Kein Senden.

```
lib/features/mesh/application/
  mesh_link.dart          Transport-Schnittstelle: Rahmen rein, Rahmen raus
  mesh_serial_link.dart   USB — Desktop und Android
  mesh_tcp_link.dart      WLAN — jeder Desktop, keine neue native Abhängigkeit
  mesh_ble_link.dart      Bluetooth — Telefone, zuletzt
  meshcore_frames.dart    Rahmenformat: erstes Byte ist die Art
```

Die drei Transporte hinter **einer** Schnittstelle, und TCP zuerst: Es
braucht nur einen Socket, funktioniert auf allen drei Desktops und ist die
einzige Variante ohne neues natives Paket. Bluetooth ist der aufwendigste
und kommt zuletzt, obwohl er auf dem Telefon der übliche Weg ist.

Der Rahmen ist ein Binärformat mit einem Typ-Byte, kein Protobuf. Das ist
in Dart überschaubar und ohne Codegenerator zu erledigen.

**Fertig, wenn:** Ein angeschlossener Knoten wird erkannt, seine Kontakte
stehen auf dem Bildschirm, ankommende Nachrichten erscheinen.

### Stufe 2 — Speichern

Zwei neue Tabellen, Schema 14:

```
mesh_contacts   clientId, publicKey, name, lastHeard, ...
mesh_messages   clientId, contactId, direction, body, sentAt, state, ...
```

Beide wandern durch den bestehenden Schnappschuss, also über den
gemeinsamen Ordner, das örtliche Netz und die Bilderfolge. Dann steht eine
auf dem Telefon empfangene Nachricht auch auf dem Rechner.

**Die Migration darf nichts annehmen.** Jeder Schritt sieht nach, ob es
die Spalte schon gibt — siehe `_addColumnOnce` in `local_db/database.dart`
und die Begründung dort. Das war ein echter Ausfall, kein Lehrbuchfall.

**Notfallkarten gehen nicht ins Funknetz.** Nicht als Vorlage, nicht als
Beilage, nicht auf Nachfrage. Gesundheitsdaten über ein Funknetz mit
öffentlich bekanntem Voreinstellungsschlüssel ist ein Datenschutzunfall
mit Ansage.

### Stufe 3 — Senden

Direktnachrichten an bekannte Kontakte. Der Bildschirm zählt die Zeichen
mit und sagt bei Überlänge, dass geteilt wird, statt es still zu tun.

Eine Nachricht ohne Quittung ist **unterwegs**, nicht **zugestellt**, und
die Oberfläche muss diese drei Zustände auseinanderhalten: gesendet,
quittiert, aufgegeben. Ein Häkchen, das „abgeschickt" meint und wie
„angekommen" aussieht, ist in dieser App gefährlicher als in jeder
anderen.

### Stufe 4 — Die vier Dinge von oben

Warnung weiterreichen, Standort auf der Karte, Vorlagen aus dem
Notfallplan. Erst hier wird es eine PreppSuite-Funktion statt einer
zweiten Chat-App.

## Was im Bildschirm stehen muss

Dieselbe Nüchternheit wie beim Notfunk, wo die App schon sagt, was
verboten ist und nicht nur, was erlaubt ist.

- **Es kommt Gerät dazu.** Bisher läuft die App auf dem, was man hat. Das
  hier braucht ein Funkgerät für 20–40 Euro, und ohne eines darf nichts
  schlechter werden als vorher.
- **Die Sendezeitbegrenzung ist nicht erledigt, nur berücksichtigt.**
  Zehn Prozent je Stunde deckt eine Bedingung ab. Gerätekonformität,
  Strahlungsleistung und Bandbreite bleiben Sache dessen, der sendet —
  und die App fordert zum Senden auf.
- **Reichweite ist keine Zusage.** Sie hängt zu etwa 60 % am Standort. Die
  App kann sie weder messen noch versprechen.
- **Kanal ist nicht privat.** Der Voreinstellungskanal hat einen
  öffentlich bekannten Schlüssel. Wer vertraulich schreiben will, braucht
  Direktnachrichten mit Schlüsselpaar, und das muss dastehen.

## Was nicht gebaut wird

**Der Haushaltsabgleich über Funk.** Die Rechnung, damit sie nicht noch
einmal geführt werden muss:

Die europäische Voreinstellung LONG_FAST liefert **1,07 kbit/s**, geteilt
vom gesamten Netz. Eine Nachricht mit zehn Zeichen belegt **354 ms** und
sperrt den Knoten durch die 10-%-Grenze für **3,5 Sekunden**.

Die 147 Checklistenpunkte aus dem echten Haushalt sind als Abgleichsdatei
**45,9 KB**. Mit zweihundert Vorratszeilen kommt man auf rund **113 KB**:

```
496 Pakete zu 233 Byte
~17 Minuten reine Sendezeit
~2,8 Stunden mit der Sendezeitbegrenzung
```

Und das ist geschönt, weil Fluten den Kanalverbrauch vervielfacht. Ein
Haushalt, der seinen Vorrat abgleicht, macht das Funknetz für alle anderen
in Reichweite für einen halben Tag dicht.

**Dateien, Fotos, Karten.** Aus demselben Grund, nur deutlicher.

**Ein eigenes Funkprotokoll.** Es gibt zwei gewachsene Netze mit echten
Knoten auf echten Dächern. Ein drittes zu erfinden hieße, bei null
Reichweite anzufangen.

## Aufwand

Stufe 1 und 2 sind der Großteil: Rahmenformat, Transporte, Tabellen,
Migration. Grob zwei Wochen bis zu einem brauchbaren Stand, plus der
Woche für Schritt 0 — die aber vorher kommt und die Antwort auch „nein"
sein lassen darf.

Das größte Risiko ist keines im Code: Ob am eigenen Ort ein Netz steht,
entscheidet über alles Weitere und lässt sich nicht programmieren.

## Quellen

- [MeshCore Companion Protocol](https://docs.meshcore.io/companion_protocol/)
- [Meshtastic Client API (Serial/TCP/BLE)](https://meshtastic.org/docs/development/device/client-api/)
- [MeshCore und Meshtastic im Vergleich, HanseMesh](https://hansemesh.de/anleitungen/meshcore-vs-meshtastic/)
- [Meshtastic und MeshCore im europäischen Rechtsrahmen, rf.guru](https://shop.rf.guru/pages/meshtastic-meshcore-and-the-legal-framework)
- [Kritische Analyse des Meshtastic-Protokolls, disk91](https://www.disk91.com/2024/technology/lora/critical-analysis-of-the-meshtastic-protocol/)
