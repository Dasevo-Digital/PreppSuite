# Anfrage an IFRC und GFARC

Entwurf eines Briefes, mit dem um die Erlaubnis gebeten wird, die
sprachlosen Erste-Hilfe-Videos des Global First Aid Reference Centre in
ein Videopaket für PreppSuite aufzunehmen — und mit dem zugleich
gemeldet wird, dass die Leitlinien 2025 als Quelle benutzt werden.

Geschrieben, nicht abgeschickt. Absenden ist deine Sache.

## Warum überhaupt fragen

Die Videolage ist gemessen, nicht vermutet. Die e-Library des GFARC hat
409 Einträge; davon sind **neun Videodateien wirklich herunterladbar**,
und das sind drei Filme in je vier Sprachen — Englisch, Französisch,
Spanisch, Arabisch. Kein Deutsch, und Kampagnenclips, keine Anleitungen.

Alles andere liegt auf YouTube. Darunter die elf Filme der Reihe **„Mime
first aid"**: Erdbeben, Hochwasser, Giftwolke, Warnzeichen, starke
Blutung, Bewusstlosigkeit, Wunden, Vergiftung, Trauma,
Sicherheitsmaßnahmen, und ein Spiel dazu. Sie sind pantomimisch, also
**ganz ohne Sprache** — und lösen damit genau das Problem, an dem jedes
deutsche Erste-Hilfe-Video scheitert: dass es keines gibt, das frei
lizenziert ist.

Genommen werden können sie nicht. Auf den YouTube-Seiten steht keine
Creative-Commons-Kennzeichnung, also gilt die Standardlizenz, und
YouTubes Bedingungen verbieten das Herunterladen. Die Nutzungsbedingungen
des GFARC verbieten die Vervielfältigung „for any use other than for
private or educational purposes … without specific prior written
authorization". Genau diese Erlaubnis wird hier erbeten.

## An wen

| | |
|---|---|
| **first.aid@ifrc.org** | Der „webmaster", den die Nutzungsbedingungen des GFARC für solche Anfragen nennen. Hauptadressat. |
| **secretariat@ifrc.org** | Die Adresse von der Impressumsseite der Leitlinien. In Kopie, wegen des zweiten Punktes. |

## Was du vor dem Abschicken entscheiden musst

1. **Absender.** Unten steht `<Name>`. Ich setze deinen Namen und deine
   Anschrift nicht selbst ein.
2. **Quelltext.** Der Brief bietet an, die App auf Anfrage zu schicken.
   Er behauptet **nicht**, dass der Quelltext öffentlich einsehbar ist,
   denn das Gitea ist privat. Wenn du das anders willst, muss vorher ein
   öffentliches Spiegel-Repository her — sonst ist die Aussage falsch.
3. **Das Emblem.** Der Brief fragt danach ausdrücklich, statt es zu
   übergehen. Jeder dieser Filme zeigt das Rote Kreuz, und das Emblem ist
   in Deutschland durch das Rotkreuzgesetz geschützt, unabhängig vom
   Urheberrecht am Film.

## Der Brief

Auf Englisch, weil das GFARC in Paris sitzt und die IFRC in Genf, und
Englisch die gemeinsame Sprache beider ist.

---

**Subject:** Permission request — GFARC "Mime first aid" videos in a free,
non-commercial offline app

Dear Global First Aid Reference Centre,

I am writing to ask for written permission under your Terms of use, and to
report a use of the Guidelines 2025 as your copyright page invites.

**Who is asking.** PreppSuite is a household preparedness application for
Germany. It is free of charge and non-commercial: no account, no server, no
advertising, no tracking, no payment of any kind. It runs fully offline on
macOS, Windows, Linux, Android and iOS. Its first aid section is the one
part that must work with no download and no network at all, and it
currently ships seventeen written guides with line drawings and a
metronome for chest compressions.

**What I would like to ask for.** Video is an optional add-on in our app,
downloaded separately, and we ship none today — because we could not find
material we are allowed to carry. The eleven films of your "Mime first
aid" series would change that, for one reason above all others: they carry
no spoken and no written language. Freely licensed German-language first
aid video barely exists, and a wordless film sidesteps the problem
entirely.

Concretely, I ask for three things:

1. Permission to redistribute those eleven films **unchanged**, inside an
   optional video pack that our users download and then play offline. Each
   film would name the Global First Aid Reference Centre as its author and
   state your terms on the screen directly beneath it.
2. Access to the source files. Your resource pages link the films on
   YouTube only, and downloading from there is neither permitted nor
   something I would do without asking.
3. Your guidance on the **emblem**. The films show the Red Cross emblem.
   I would like your confirmation that showing it inside your own
   unaltered film is covered by this permission, and the wording you want
   used. The emblem will not appear anywhere else in the application — not
   in its icon, not in its interface, not in its listings.

I will gladly accept any restriction you attach: non-commercial use only,
no modification, no re-hosting, withdrawal on request.

**The second matter, briefly.** The copyright page of the *International
first aid, resuscitation and education guidelines 2025* permits copies for
non-commercial use with the source acknowledged, and says the IFRC would
appreciate receiving details of its use. This is that notice: we are
writing new German lay-language guides on **psychological first aid** and
acute mental distress, using the Guidelines as the cited source. The
wording is our own — this is not a translation — and each guide names the
Guidelines on the screen where it is read.

Two questions follow from that. Is naming the Guidelines on each guide's
own screen the acknowledgement you want, or do you have a preferred form?
And would a German translation of the "First aid steps" blocks be
permitted? I ask because our program code is under the MIT licence, which
would allow others to sell copies, whereas your permission is
non-commercial. We would therefore carry your material under your terms,
stated separately from the code licence — which is how we already carry
OpenStreetMap and Open Food Facts data.

I am happy to send you a build of the application, or its source, so you
can see exactly what is being asked for.

With thanks for your work,

\<Name\>
\<Anschrift\>
\<E-Mail\>

---

## Was danach passiert

Kommt die Erlaubnis, ist die technische Seite fertig vorhanden: das
Paketformat in [erste-hilfe.md](erste-hilfe.md) trägt `credit` und
`licence` je Film und zeigt beides unter dem Video, und
`tool/erste_hilfe_paket.sh` baut das Paket aus einem Ordner und einer
`videos.tsv`. Die elf Filme müssten den Anleitungskennungen zugeordnet
werden; `--ids` listet sie.

Kommt sie nicht, ändert sich nichts. Keine Anleitung hängt an einem
Video.
