# Erste Hilfe

Anleitungen, Zeichnungen und ein Taktgeber für die Herzdruckmassage.
Alles davon ist beim ersten Start da, ohne Netz, ohne Download und ohne
eine einzige Einstellung.

Videos sind ein eigener, nachladbarer Zusatz. Warum, steht weiter unten.

## Warum das nicht im Wissen-Bereich liegt

Der Wissen-Bereich ist eine Enzyklopädie hinter einem Archiv von mehreren
Gigabyte. Wer das nicht heruntergeladen hat, findet dort nichts – und wer
neben einem Verletzten kniet, hat es nicht heruntergeladen.

Erste Hilfe ist der eine Bereich, der ohne Voraussetzung funktionieren
muss. Deshalb ist er ein eigener Bereich und nicht eine Ecke eines
anderen.

Zu finden unter **Notfall → Erste Hilfe**, als erster Eintrag. Über jeder
dieser Seiten steht ein Streifen, der 112 wählt; wer drei Bildschirme tief
beim allergischen Schock liest, muss zum Anrufen nicht zurückfinden.

## Woher die Inhalte kommen

Siebzehn der zweiundzwanzig Anleitungen folgen den
**Reanimationsleitlinien 2025 des European Resuscitation Council** in der
deutschen Fassung des German Resuscitation Council und deren
Erste-Hilfe-Kapitel. Die Vergiftungsseite nennt die
Giftinformationszentren der Länder, die Hitzeseite zusätzlich die BZgA.

Die fünf Anleitungen unter **Seelische Not** folgen einer anderen Quelle,
den *International first aid, resuscitation and education guidelines 2025*
der IFRC — warum, steht weiter unten in einem eigenen Abschnitt.

### Was der Schritt von 2021 auf 2025 geändert hat

Für Laien keine einzige Zahl: 30:2, 5 bis 6 cm, 100 bis 120 in der Minute
stehen unverändert. Geändert hat sich die Reihenfolge und die Betonung.

- Der **Notruf kommt vor die Atemkontrolle**, mit dem Telefon auf
  Lautsprecher, und die Leitstelle leitet weiter an — damit früher
  gedrückt wird. Die App hatte das schon so.
- **Schnappatmung ist keine normale Atmung.** Stand ebenfalls schon da.
- **Nicht erst umlagern und ausziehen.** Einer von zwei Punkten, an denen
  die App der Fassung von 2025 widersprach: sie verlangte Brustkorb frei
  und harte Unterlage, bevor jemand anfängt. Jetzt heißt der Schritt
  „Sofort anfangen, wo die Person liegt".
- **Bei Kindern geht der Notruf jetzt zuerst hinaus.** Der zweite. Bis
  2021 galt für den Einzelhelfer: erst eine Minute wiederbeleben, dann
  anrufen — begründet damit, dass ein Kind Sauerstoff braucht und der
  Helfer zum Telefonieren weggeht. Mit dem Telefon auf Lautsprecher geht
  niemand mehr weg, und 2025 gleicht die Kinderreanimation an die der
  Erwachsenen an. Die fünf ersten Beatmungen, 15:2 und ein Drittel der
  Brustkorbtiefe bleiben unverändert.

  Zur Belastbarkeit dieses Punktes: er stützt sich auf die Kurzfassung
  „Lebenserhaltende Maßnahmen bei Kindern" und auf eine zweite Darstellung
  („Kinder sollen im Zweifelsfall wie Erwachsene reanimiert werden"),
  nicht auf den Volltext — der liegt hinter einer Anmeldung. Die Änderung
  geht in die ungefährliche Richtung: früher anrufen kostet nichts, eine
  Minute später anrufen war genau das, was gestrichen wurde.

Was diese Seite **nicht** behauptet: dass die deutschen Lehraussagen für
Erste-Hilfe-Kurse umgestellt sind. Die stimmen Arbeiter-Samariter-Bund,
DLRG, Johanniter, Malteser und DRK gemeinsam über die
Bundesarbeitsgemeinschaft Erste Hilfe ab, zu einem festgelegten Zeitpunkt
und nicht jede Organisation für sich — der DRK-Bundesarzt hat das im
Rundschreiben vom 24.11.2025 ausdrücklich festgehalten: „Bis dahin gelten
die bestehenden Lehraussagen unverändert weiter." Ob der gemeinsame
Stichtag inzwischen liegt, war beim Schreiben dieser Zeilen nicht
öffentlich zu belegen. Da sich keine Zahl ändert, widersprechen die
Anleitungen einem Kurs in keinem Fall; wo doch, gilt der Kurs.

Jede Anleitung nennt ihre Quelle auf dem Bildschirm. Das ist dieselbe
Regel wie bei den Kältestunden im Stromausfall: Diese App stellt keine
eigenen medizinischen Aussagen auf, und wo sie fremde wiedergibt, sagt
sie wessen.

Was bewusst fehlt: alles, was ohne Ausbildung nicht sicher anzuwenden
ist, und jede Dosierung eines Medikaments, das nicht dem Verletzten
selbst verordnet wurde.

## Wo die Texte liegen

Nicht in der Datenbank und nicht in den ARB-Dateien.

Nicht in der Datenbank, weil das keine Haushaltsdaten sind: niemand
bearbeitet sie, nichts gleicht sie ab, und eine Anleitung, die per
Abgleich von einem Gerät mit einer älteren Fassung ankommt, wäre
schlimmer als keine.

Nicht in den ARB-Dateien, weil medizinischer Text als Fließtext prüfbar
sein muss. Zweiundzwanzig Anleitungen sind rund dreihundert
Zeichenketten; verteilt über tausendvierhundert Zeilen Oberflächentext
könnte sie niemand am Stück gegen die Leitlinie lesen.

Sie liegen in

- `lib/features/first_aid/application/first_aid_guides_de.dart`
- `lib/features/first_aid/application/first_aid_guides_en.dart`

je eine Datei pro Sprache, jede an einem Stück lesbar.
`test/features/first_aid/first_aid_guides_test.dart` hält beide auf
dieselben Kennungen, dieselbe Reihenfolge und dieselbe Zahl an Schritten,
Warnungen und Kennzahlen fest. Eine Übersetzung, die stillschweigend einen
Schritt verliert, verliert einen Schritt einer Wiederbelebung.

Die Kennung einer Anleitung (`cpr-adult`, `recovery-position`, …) ist über
Fassungen und Sprachen hinweg stabil. Ein Video aus einem Paket nennt sie,
um zu sagen, wozu es gehört – wer eine umbenennt, verwaist jedes Video,
das darauf zeigte.

## Seelische Not

Fünf Anleitungen, die nicht dem ERC folgen: psychische Erste Hilfe,
Suizidgedanken, Angst und Panikattacke, nach einem schweren Erlebnis,
akute Trauer.

### Warum sie hierhergehören

Weil diese App von Krisen handelt und eine Krise ihren Schaden auch bei
denen anrichtet, die nicht bluten. Nach Hochwasser, Brand, Unfall oder
einer Todesnachricht steht jemand daneben, der etwas tun will und nicht
weiß, was. Das ist dieselbe Lage wie bei einer Blutung — nur dass es dafür
bisher keine Seite gab.

Sie stehen **zuletzt** in der Liste, und das ist Absicht: die Reihenfolge
ist Dringlichkeitsreihenfolge, und nichts davon tötet in den nächsten vier
Minuten.

### Woher sie kommen

Aus den *International first aid, resuscitation and education guidelines
2025* der IFRC, veröffentlicht am 23.03.2026. Jedes ihrer Themen hat einen
Block „First aid steps" mit nummerierten Laienschritten — dieselbe Form,
die diese App ohnehin benutzt.

Die Impressumsseite der Leitlinien erlaubt das ausdrücklich:

> Copies of all or part of this study may be made for non-commercial use,
> providing the source is acknowledged.

Das ist keine Creative-Commons-Lizenz und es ist auch keine
Übersetzungserlaubnis. Deshalb ist hier **nichts übersetzt**: die
Reihenfolge der Handgriffe ist die der Leitlinien, die Worte sind die
dieser App, und jede Anleitung nennt das Kapitel, aus dem sie stammt, auf
dem Bildschirm. Der Programmcode steht unter der MIT-Lizenz, die den
Weiterverkauf erlaubt — fremder Inhalt unter einer Nicht-kommerziell-
Bedingung darf darin nicht wörtlich liegen.

### Was bewusst fehlt, obwohl es überall steht

**Die Tüte vor dem Mund** und **die „fünf Dinge, die du siehst"**. Beides
ist weit verbreitet, und die Leitlinien 2025 sprechen für beides
ausdrücklich keine Empfehlung aus (Kapitel „Anxiety and panic", Abschnitt
zur Delphi-Methode: *„Guidance on specific treatments for a panic attack
(e.g. breathing into a paper bag, repeating coping statements, grounding
techniques) was not endorsed"*). Empfohlen ist das Vor- und Mitatmen —
ein auf 1 durch die Nase ein, auf 3 durch den Mund aus —, und mehr steht
deshalb auch nicht da.

Das ist dieselbe Regel wie überall sonst in diesem Bereich: was hier steht,
steht in einer Leitlinie, und was nicht drinsteht, steht hier nicht.

### Die Rufnummern

Auf den Seiten stehen die deutschen Nummern, jede zum Antippen: die
TelefonSeelsorge (0800 111 0 111, 0800 111 0 222 und die europaweite
116 123), die Nummer gegen Kummer für Kinder und Jugendliche (116 111),
der ärztliche Bereitschaftsdienst (116 117) und 112.

Die Leitlinien nennen keine Rufnummern — sie sind international und
verweisen für Anlaufstellen auf den jeweiligen Landesverband. Die Nummern
hier sind deshalb ausdrücklich als zweite Quelle auf dem Bildschirm
genannt.

## Der Taktgeber

Das ist das eine, was eine App während einer Wiederbelebung kann und eine
gedruckte Karte nicht. Wer drückt, kann nicht gleichzeitig bis
hundertzehn und bis dreißig zählen, auf einen Brustkorb sehen und mit der
Leitstelle sprechen; sich selbst überlassen, driften die meisten deutlich
unter den Leitlinienwert.

Drei Kanäle, weil jeder einzelne irgendwo ausfällt: der Ton geht im Lärm
unter und fehlt auf einem Linux-Rechner ohne GStreamer, die Vibration gibt
es auf dem Schreibtisch nicht, und das Blinken hilft nicht, wenn niemand
hinsieht. Zusammen kommen sie an.

Der Bildschirm bleibt an, solange er läuft – ohne das schliefe er nach
einer halben Minute ein und nähme Takt und Zählung mit.

Die Zahl ist eine reine Funktion der verstrichenen Zeit
(`compression_pacer.dart`), kein Zähler, den ein Timer hochzählt. 110 in
der Minute sind 545.454,54… Mikrosekunden; ein zählender Taktgeber wäre
nach zwei Minuten mehrere Schläge daneben, und dann käme die Aufforderung
zu beatmen an der falschen Stelle.

Der Ton ist eine selbst erzeugte WAV-Datei von 2,5 kB
(`assets/sounds/metronome_click.wav`, erzeugt wie in der Versionsgeschichte
beschrieben) – keine Lizenzfrage, kein Download.

## Die Zeichnungen

Strichzeichnungen im Code, keine Bilddateien, und Piktogramme, keine
Illustrationen (`presentation/first_aid_drawings.dart`).

Ein Piktogramm wird schneller gelesen als ein Foto. Gezeigt wird immer
genau eine Beziehung – die Hände zum Brustbein, das Knie zum Boden – und
ein Bild, das nur diese enthält, ist auf Armlänge, auf einem Fußboden, bei
schlechtem Licht lesbar. Genau dort wird es benutzt.

Außerdem stimmt es in beiden Erscheinungsbildern: eine eingescannte
Zeichnung auf weißem Papier ist um drei Uhr nachts ein weißes Rechteck.
Und es kostet ein paar hundert Byte statt zehn Kilobyte mal jede
Bildschirmdichte.

## Videos

### Warum sie nicht mitgeliefert werden

Drei Gründe, in dieser Reihenfolge:

**Größe.** Zehn Clips von zwei Minuten in ansehbarer Auflösung sind 200
bis 300 MB, gegen eine App von 36 MB. Alle würden sie tragen, auch wer sie
nie öffnet.

**Recht.** Das Material der Hilfsorganisationen ist durchweg „alle Rechte
vorbehalten". Frei lizenzierte deutsche Erste-Hilfe-Videos gibt es kaum.
Nachgezählt statt vermutet — siehe unten.

### Woher man welche bekommt

Die App verweist auf **kein** fertiges Paket, weil es keines gibt. Wer
eines bauen will, fängt realistisch bei **Wikimedia Commons** an — der
einzigen nachprüfbaren Quelle mit frei lizenziertem Bewegtbild zum Thema.

Nachgesehen am **22.09.2026**, damit hier eine Zahl und keine Vermutung
steht:

* `Category:Videos of first aid` **existiert nicht**.
* `Category:Videos of cardiopulmonary resuscitation` enthält **acht**
  Dateien. Überwiegend nicht auf Deutsch — slowenisch, spanisch,
  niederländisch, walisisch —, und eine davon zeigt die Reanimation eines
  Hundes.

Das ist genau die Dünnheit, die oben als Grund steht, und keine Basis für
ein mitgeliefertes Paket. Die Lizenz steht bei Commons je Datei auf ihrer
eigenen Seite und muss **einzeln** geprüft werden; die Kategorieseite sagt
nichts darüber. Was am Ende im Paket landet, trägt `credit` und `licence`
und steht später unter dem Video — siehe unten.

#### Was beim Roten Kreuz liegt, nachgezählt am 25.09.2026

Die e-Library des Global First Aid Reference Centre hat **409 Einträge**.
Maschinell geprüft, welche davon eine herunterladbare Videodatei
enthalten:

* **neun Dateien** — und das sind drei Filme in je vier Sprachen, Englisch,
  Französisch, Spanisch, Arabisch. **Kein Deutsch.** Kampagnenclips, keine
  Anleitungen.
* Alles andere sind Verweise auf YouTube.

Darunter die elf Filme der Reihe **„Mime first aid"** — Erdbeben,
Hochwasser, Giftwolke, Warnzeichen, starke Blutung, Bewusstlosigkeit,
Wunden, Vergiftung, Trauma, Sicherheitsmaßnahmen. Sie sind pantomimisch,
also **ganz ohne Sprache**, und lösen damit genau das Problem, an dem
deutsche Erste-Hilfe-Videos scheitern. Genommen werden dürfen sie
trotzdem nicht: auf den YouTube-Seiten steht keine
Creative-Commons-Kennzeichnung, also gilt die Standardlizenz; die
Nutzungsbedingungen des GFARC verlangen für alles außer privatem und
Unterrichtsgebrauch eine vorherige schriftliche Erlaubnis; und jeder
dieser Filme zeigt das **Rote Kreuz**, das in Deutschland durch das
Rotkreuzgesetz unabhängig vom Urheberrecht geschützt ist.

Bleibt: fragen. Der Entwurf dafür liegt in
[`anfrage-ifrc.md`](anfrage-ifrc.md).

**Nutzen im Ernstfall.** Video ist dort das falsche Medium: eine Hand ist
belegt, spulen geht nicht, zurückgehen auch nicht. Was hilft, ist große
Schrift und Ton. Ein Video ist etwas für den Abend, an dem man sich die
Handgriffe in Ruhe ansieht.

Deshalb: ein eigenes Paket, zwei Wege hinein, und keine Anleitung hängt
davon ab.

### Das Paketformat

Ein Paket ist eine Beschreibung namens `paket.json` und die Dateien, die
sie nennt.

```json
{
  "format": 1,
  "name": "Erste Hilfe – Videopaket",
  "language": "de",
  "baseUrl": "https://example.org/eh/",
  "videos": [
    {
      "id": "hdm",
      "guide": "cpr-adult",
      "title": "Herzdruckmassage",
      "file": "hdm.mp4",
      "credit": "Jane Doe",
      "licence": "CC BY-SA 4.0",
      "url": "hdm.mp4",
      "seconds": 95,
      "bytes": 12345678,
      "sha256": "…"
    }
  ]
}
```

| Feld | Bedeutung |
|---|---|
| `format` | 1. Ein höherer Wert wird mit einem Satz abgelehnt, nicht halb gelesen. |
| `guide` | Die Kennung der Anleitung. `tool/erste_hilfe_paket.sh --ids` listet sie. |
| `file` | Ein reiner Dateiname. Ein Name mit Pfadanteil wird verworfen – eine Beschreibung kommt aus dem Netz, und eine, die `../../` nennen dürfte, wäre ein Weg, irgendwohin zu schreiben. |
| `url` | Absolut oder relativ zu `baseUrl`. Fehlt sie, ist das Paket nur als Datei zu bekommen. |
| `bytes`, `sha256` | Werden nach dem Laden geprüft. Passt etwas nicht, wird die Datei gelöscht statt behalten. |
| `credit`, `licence` | Stehen unter dem Video. Die meisten freien Lizenzen verlangen das, und der Zuschauer beurteilt danach, was er da sieht. |

### Ein Paket bauen

```bash
tool/erste_hilfe_paket.sh --ids          # welche Anleitungen es gibt
tool/erste_hilfe_paket.sh <ordner> [basis-url] [paketname]
```

Der Ordner enthält die Videodateien und eine `videos.tsv` mit einer Zeile
je Clip:

```
datei	anleitung	titel	urheber	lizenz	sekunden
hdm.mp4	cpr-adult	Herzdruckmassage	Jane Doe	CC BY-SA 4.0	95
```

Heraus kommen `paket.json` – mit Bytezahl und Prüfsumme jeder Datei – und
`ErsteHilfe-Videopaket.zip`.

### Zwei Wege hinein

**Über das Netz.** Die Adresse der `paket.json` unter **Erste Hilfe →
Videopaket** eintragen. Die App zeigt erst, was im Paket steckt und wie
groß es zusammen ist, und lädt dann auf Zuruf – einen Clip nach dem
anderen, jeden wieder aufnehmbar, jeden gegen Größe und Prüfsumme
geprüft. Was fehlschlägt, wird namentlich genannt; der Rest wird trotzdem
installiert.

Die App bringt **keine** Adresse mit. Eine fest eingebaute Adresse, unter
der noch nichts veröffentlicht ist, wäre ein 404 vor jedem Haushalt und
ließe eine funktionierende Sache kaputt aussehen.

**Aus einer Datei.** Die Zip auswählen. Sie wird als Strom gelesen und
Eintrag für Eintrag herausgeschrieben – ein Paket von einigen hundert
Megabyte im Speicher zu entpacken ist, wie eine App auf einem Telefon vom
System abgeräumt wird. Geschrieben wird nur, was die Beschreibung selbst
nennt.

Das ist der Weg, der ohne Netz funktioniert, also in der Lage, für die
diese App gebaut ist.

### Wo die Dateien liegen

Im gewöhnlichen Download-Ordner, Unterordner `ErsteHilfe` – aus demselben
Grund wie die Archive: groß, von Hand auf das nächste Gerät kopierbar,
ohne die App löschbar.

### Wiedergabe

In der App auf Android, iOS und macOS. Unter Linux und Windows gibt es
keine Umsetzung von `video_player`; dort wird die Datei an das
Abspielprogramm des Systems übergeben – dieselbe Teilung wie beim
Artikel-Leser, aus demselben Grund.
