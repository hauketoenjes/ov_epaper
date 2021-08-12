# OV ePaper Downloader

Das CLI Tool downloaded die aktuell Ausgabe (oder ältere Ausgaben) der [Oldenburgischen Volkszeitung (OV)](https://oldenburgische-volkszeitung.de/epaper-archiv.php) aus dem ePaper Archiv und generiert ein PDF daraus.

## Warum funktioniert das?
Das Tool basiert darauf, dass die OV einzelne Bilddateien nutzt, um die Zeitung im Web hinter einem Login anzuzeigen. Aus diesen Bilddateien wird dann eine Seite der Zeitung zusammengebaut. Das Interessante ist, dass die Download URL's für die Bilder ohne Login oder Token erreichbar sind. Grundsätzlich ist das kein Problem, diese URL's sind aber vorhersagbar:

Eine typische URL sieht wie folgt aus: 

```
https://oldenburgische-volkszeitung.de/lib/epaper/img/2021/20210719-ov/tiles/a16-21-07-19-ov-01-_01-4c-hp/2-0-0.jpg
```

Im Wesentlichen besteht die URL aus folgenden Paramtern:
- Datum der Ausgabe (2x): `/2021/20210719` und `21-07-19`
- Seite: `01-_01`
- Position und Größe des JPEG Tiles: `2-0-0.jpg`
- Ein Wert vor der Tile Position: Hier: `hp`

Das einzige, was nicht 100%ig vorhersagbar ist folgendes:
- Das `a16` vor dem zweiten Datum. Es scheint aber nur zwei mögliche Werte zu geben: `a16` und `a17`.
- Die Buchstabenkombination vor der Tile Position nicht immer die gleiche. Hier habe ich bis jetzt aber nur zwei mögliche Kombinationen gesehen: `hp` und `vp`.

Der Rest der URL bleibt immer gleich. Somit kann das Skript einfach checken, ob die aktuelle Ausgabe `a16` oder `a17` und `hp` oder `vp` in der URL hat und alle Tiles herunterladen.

Die vollständige URL mit Parametern sieht dann wie folgt aus:
```
https://oldenburgische-volkszeitung.de/lib/epaper/img/{yyyy}/{yyyyMMdd}-ov/tiles/{a16 | a17}-{yy}-{MM}-{dd}-ov-{page}-_{page}-4c-{hp | vp}/2-{x}-{y}.jpg
```

## Wie das Skript arbeitet

1. Datum abfragen
2. Testen, ob `a16` oder `a17` und `hp` oder `vp` in der URL steht
3. Alle Tiles herunterladen (`6*4 Tiles pro Seite * X Seiten`) und in einem temporären Ordner speichern
4. PDF aus den heruntergeladenen Tiles generieren
5. Temporären Ordner löschen

## Wie man das Problem lösen kann

Es gibt im Grunde zwei Optionen: 
1. Die Endpunkte zum Laden der Bilder mit einem Token sicher, wie es z.B. auch mit der Website funktioniert.
2. Einen zufälligen Part in die URL einfügen (z.B. UUID's anstatt Seitennummern) und es so unmöglich machen die URL vorherzusagen.

