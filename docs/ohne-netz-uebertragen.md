# Einen Haushalt ohne Netz übertragen

Der gemeinsame Ordner ist der Weg, der von allein läuft: Nextcloud,
Syncthing, iCloud Drive. Er setzt aber voraus, dass es diesen Ordner gibt
und dass ihn beide Geräte erreichen.

Für den Fall, dass das nicht zutrifft, gibt es zwei weitere Wege. Beide
findest du unter **Einstellungen → Teilen → Ohne Netz übertragen**.

Sie ersetzen den Ordner nicht. Sie sind für den Moment, in dem zwei
Menschen nebeneinanderstehen und ihre Stände angleichen wollen — und für
den, in dem gar nichts mehr geht.

## Über das örtliche Netz

Das schnelle Verfahren. Beide Geräte hängen im selben Netz: das WLAN
zu Hause, ein Hotspot, das Netz auf dem Campingplatz.

Ein Gerät zeigt **einen** QR-Code. Darin stehen seine Adresse und ein
frisch erzeugter Schlüssel. Das andere Gerät filmt ihn ab und verbindet
sich. Der ganze Haushalt geht in einer einzigen Anfrage hinüber — und
zwar **in beide Richtungen**: Das anfragende Gerät schickt, was es hat,
das andere führt es zusammen und antwortet mit seinem Stand. Danach sind
beide auf demselben Stand, nicht eines auf das andere kopiert.

**Der QR-Code ist der Türschlüssel, nicht die Straße.** Das ist der
ganze Sicherheitsentwurf, und er kommt ohne Kopplungszeremonie aus: Wer
den Bildschirm sehen kann, kommt herein, sonst niemand. Es gibt nichts zu
erraten, keinen Namen, kein Standardkennwort und keine Suche im Netz, die
sich vortäuschen ließe.

Der Inhalt ist trotzdem verschlüsselt, obwohl er das örtliche Netz nie
verlässt. „Örtliches Netz" heißt auf einem Telefon oft genug: ein Café,
ein Hotel, ein Campingplatz. Der Schlüssel gilt für diese eine
Übertragung.

Die Daten gehen **nicht** über das Internet. Kein Server, kein Konto,
kein Dienst dazwischen.

## Als Bilderfolge

Das Verfahren, das gar nichts voraussetzt. Kein Netz, kein Ordner, keine
Kopplung — zwei Geräte mit einem Bildschirm und einer Kamera genügen.

Ein Gerät zeigt eine Folge von QR-Bildern, das andere filmt sie ab. Die
Bilder laufen **in einer Schleife**, immer wieder von vorn. Genau das
macht es ohne Rückkanal benutzbar: Das sendende Gerät kann gar nicht
erfahren, welche Bilder angekommen sind, also wiederholt es einfach alles.
Ein verpasstes Bild kommt beim nächsten Durchlauf von allein wieder. Wer
das Telefon hält, muss nicht genau zielen, sondern nur weiter halten.

Die Geschwindigkeit lässt sich umstellen. Der richtige Wert ist keine
Konstante — er hängt von Kamera, Licht und Bildschirm ab, und auf dem
Bildschirm ist ablesbar, ob Bilder ankommen.

Ein Haushalt mit zweihundert Vorratszeilen sind ungefähr **vier Bilder**.
Die Daten werden vorher gepackt.

## Zwei verschiedene Haushalte

Nennt der Code einen anderen Haushalt als den, zu dem das Gerät gehört,
wurde das früher abgelehnt. Als **Grundeinstellung** ist das richtig: zwei
zusammengeführte Datenbestände sind nicht wieder zu trennen, das darf also
nie versehentlich passieren. Als Antwort an jemanden, der es so *meint*,
taugt es nicht — zwei Geräte eines Haushalts, die getrennt eingerichtet
wurden, bevor es den Beitritt bei der Ersteinrichtung gab, hatten keinen
Weg zueinander.

Seit 1.9.1 wird deshalb gefragt statt entschieden, mit den Zeilenzahlen auf
dem Bildschirm:

- **Zusammenführen** — die eigenen Zeilen werden auf den anderen Haushalt
  umgestempelt und wandern beim Abgleich mit hinüber, dessen Daten kommen
  hierher. Nichts geht verloren. Das funktioniert ohne Änderung am
  Protokoll, weil der Gast seinen Stand *nach* dem Umstempeln liest — der
  Gastgeber sieht also einen Stand seines eigenen Haushalts und lehnt ihn
  nicht mit 409 ab.
- **Eigene Daten verwerfen** — gelöscht wird *vor* dem Umstempeln, sonst
  wanderten die Zeilen unter der neuen Kennung mit und die Wahl liefe ins
  Leere.
- **Nichts ändern** — es wird nichts angefasst. Soll stattdessen das andere
  Gerät beitreten, wird der Code in der anderen Richtung gezeigt.

Bei der **Ersteinrichtung** wird nicht gefragt, sondern übernommen: dort
hat das Gerät noch keine eigenen Zeilen, es ist also nichts abzuwägen.

Der gemeinsame Ordner verhält sich hier anders und tut es ungefragt: wer
einen Ordner mit fremdem Haushalt wählt, tritt ihm bei und erfährt es
hinterher. Das ist eine offene Unstimmigkeit, keine Absicht.

## Was übertragen wird

Derselbe Schnappschuss wie im gemeinsamen Ordner: Vorräte, Checklisten,
Budget, Notfallplan und die Notfallkarten. Es gelten dieselben
Zusammenführungsregeln — die neuere Fassung einer Zeile gewinnt, gelöschte
Zeilen bleiben als Grabstein.

Deshalb ist es **unschädlich, dasselbe zweimal zu übertragen**. Beim
zweiten Mal ändert sich nichts. Wer unsicher ist, ob es geklappt hat,
macht es einfach noch einmal.

Ein Schnappschuss aus einem **anderen Haushalt** wird abgelehnt und nicht
eingemischt. Zwei Haushalte, die sich versehentlich Zeilen teilen, lassen
sich hinterher nicht mehr trennen.

## Die Bilderfolge ist nicht verschlüsselt

Und das ist Absicht. Eine Bilderfolge kann nur abfilmen, wer im Raum
steht — die beiden sehen sich, und das ist eine bessere Zusicherung als
jeder Schlüsseltausch. Ein Kennwort zwischen zwei Menschen, die ohnehin
miteinander reden, ist Zeremonie.

Wichtig ist die Kehrseite: **Derselbe Inhalt darf niemals über Funk, Netz
oder Datei gehen, ohne verschlüsselt zu werden.** Im Schnappschuss stehen
die Notfallkarten, also Allergien, Medikamente und Vorerkrankungen. Der
Weg über das örtliche Netz verschlüsselt deshalb, obwohl er örtlich ist.

## Was auf welcher Plattform geht

| | Zeigen | Abfilmen |
|---|---|---|
| Android, iOS | ja | ja |
| macOS, Windows, Linux | ja | nur mit Kamera |

Zum Abfilmen wird eine Kamera gebraucht. Zwischen zwei Rechnern ohne
Kamera bleibt der gemeinsame Ordner oder — im selben Netz — der Weg über
das Netz, bei dem nur **ein** Gerät filmen muss.

Unter iOS und macOS fragt das System beim ersten Mal nach Zugriff auf das
örtliche Netz.
