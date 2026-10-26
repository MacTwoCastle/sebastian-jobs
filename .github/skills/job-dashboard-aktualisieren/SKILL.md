---
name: job-dashboard-aktualisieren
description: 'Aktualisiert ein bestehendes Job-Dashboard fuer einen Bewerber anhand seines CV und einer neuen Internet-Recherche. Verwenden fuer Branchen-Update, Firmenrecherche, Stellenrecherche, LinkedIn-Suchlinks und anschliessendes Ueberfuehren in das Kandidaten-Dashboard, z. B. fuer Sebastian oder Ulf.'
argument-hint: 'Kandidatenname, z. B. Sebastian oder Ulf'
user-invocable: true
---

# Job-Dashboard aktualisieren

Dieser Skill aktualisiert die Recherchebasis eines vorhandenen Kandidaten-Dashboards und ueberfuehrt die Ergebnisse in die bestehende Projektstruktur.

## Verwenden wenn

- ein vorhandenes Dashboard fuer einen Bewerber fachlich aktualisiert werden soll
- Branchen, Firmen und Stellenanzeigen aus einer neuen Internet-Recherche neu bewertet werden sollen
- LinkedIn-Suchabfragen zum CV passen muessen
- der Bewerbername als einziges zusaetzliches Argument uebergeben wird

## Erwartete Eingabe

Der Aufruf enthaelt den Namen des Bewerbers, zum Beispiel `Sebastian` oder `Ulf`.

## Standardquellen

- LinkedIn
- StepStone
- Indeed
- XING
- Karriereseiten der Firmen

## Zielstruktur im Repository

- `<Kandidat>/data/profile.json`
- `<Kandidat>/data/firmen.json`
- `<Kandidat>/data/jobs.json`
- `<Kandidat>/data/linkedin_queries.json`
- `<Kandidat>/data/herleitung.json` (falls vorhanden)
- `<Kandidat>/data/suchradius.json` (falls vorhanden)
- `<Kandidat>/<slug>_jobs_dashboard.html`
- `<Kandidat>/<slug>_suchradius.html` (separate Transparenz-Seite, siehe Schritt 9a)

Alle kandidatenbezogenen Daten und das generierte Dashboard werden ausschliesslich
im jeweiligen Kandidatenordner abgelegt. Dateien mit Kandidatenbezug duerfen nicht
im Repository-Root angelegt, aktualisiert oder dorthin kopiert werden. Eine
spaetere Veroeffentlichung in ein separates Deploy-Repository ist ein eigener
Schritt und keine Ablage im Root.

Die Feldstruktur und Qualitaetsregeln stehen in [dashboard-daten.md](./references/dashboard-daten.md).

## Arbeitsablauf

1. Kandidatenordner pruefen.
   Stelle sicher, dass `<Kandidat>/data/` existiert und die vier JSON-Dateien vorhanden sind.

2. CV-Quelle des Bewerbers ermitteln.
   Bevorzuge vorhandene aufbereitete CV-Dateien aus den Projektordnern mit CV-Exporten oder Markdown-Chunks.
   Falls kein eindeutiger CV im Workspace auffindbar ist, lies zuerst `<Kandidat>/data/profile.json` und frage den Nutzer nach dem CV-Pfad oder bestaetige explizit einen Profil-Fallback.

3. Bestehenden Suchraum verstehen.
   Lies mindestens diese Dateien des Bewerbers:
   - `<Kandidat>/data/profile.json`
   - `<Kandidat>/data/firmen.json`
   - `<Kandidat>/data/jobs.json`
   - `<Kandidat>/data/linkedin_queries.json`
   - `<Kandidat>/data/herleitung.json` (falls vorhanden)

4. CV-basierte Suchhypothese bilden.
   Leite daraus die priorisierten Rollen, Fachgebiete, Branchen, Laender, Senioritaeten, Suchbegriffe und Ausschlusskriterien ab. Halte diese Herleitung explizit fest (CV-Fakten je Kategorie und je Suchprofil-Dimension eine kurze Begruendung) fuer die spaetere Aktualisierung von `herleitung.json`.

5. Neue Internet-Recherche durchfuehren.
   Recherchiere mit den Standardquellen nach:
   - passenden Branchen fuer das Profil
   - relevanten Zielunternehmen
   - aktuellen Stellenanzeigen
   - sinnvollen LinkedIn-Query-URLs

6. Suchbreite sicherstellen (Suchradius).
   Gehe zusaetzlich zur zielgerichteten Treffer-Recherche systematisch **jede** Kategorie aus `profile.branchen` durch, auch solche ohne bisherigen Treffer. Notiere pro Kategorie mehrere real recherchierte Firmen (Treffer und Firmen ohne aktuellen Treffer) in `<Kandidat>/data/suchradius.json` (Schema in [dashboard-daten.md](./references/dashboard-daten.md)). Ziel: der Bewerber soll erkennen, dass der Suchraum breit war, auch wenn nicht jede Kategorie einen aktuellen Treffer liefert. Keine Firmen erfinden oder Portale raten.

7. Daten aktualisieren.
   Aktualisiere standardmaessig im Modus `Ergaenzen`:
   - `profile.json`: nur Felder anpassen, die aus CV und neuer Recherche direkt betroffen sind, insbesondere `subtitle`, `searchStatus`, `standDatum`, `skills`, `branchen`, `laender`, Infobox-Texte und LinkedIn-Hinweise
   - `firmen.json`: neue relevante Firmen aufnehmen, veraltete Eintraege nur entfernen, wenn sie klar unpassend oder doppelt sind
   - `jobs.json`: neue aktuelle Stellen einpflegen, Duplikate vermeiden, offensichtliche Altlasten entfernen; falls eine Anzeige beim Aufrufen als nicht mehr verfuegbar erscheint, `"linkOffline": true` setzen statt den Eintrag zu loeschen
   - `linkedin_queries.json`: Queries so aktualisieren, dass sie die Hauptrollen und Branchen des CV treffen
   - `herleitung.json`: CV-Fakten und Suchprofil-Dimensionen aus Schritt 4 aktuell halten, insbesondere die `Branchen`-Werte konsistent zu `profile.branchen` und den `branche`-Feldern in `firmen.json`/`jobs.json` (siehe [dashboard-daten.md](./references/dashboard-daten.md))

8. Qualitaet sichern.
   Pruefe vor dem Schreiben:
   - keine Dubletten bei Firmen oder Jobs
   - Match-Scores sind nachvollziehbar und relativ konsistent
   - Links zeigen direkt auf Suchseiten, Karriereportale oder Stellenanzeigen
   - Laender, Branchen und Senioritaet sind normalisiert

9. Dashboard neu generieren.
   Nach den JSON-Aenderungen das Dashboard aus den Daten neu erzeugen ueber `python3 scripts/generate_user_dashboard.py <Kandidat>` (siehe [generate_user_dashboard.py](../../../scripts/generate_user_dashboard.py)). Das Ergebnis muss unter `<Kandidat>/<slug>_jobs_dashboard.html` liegen; niemals eine kandidatenbezogene HTML-Datei im Repository-Root erzeugen oder aktualisieren. Bei Aenderungen am gemeinsamen Template ([dashboard_template.html](../../../_template/dashboard_template.html)) IMMER beide Kandidaten-Dashboards in ihren jeweiligen Kandidatenordnern regenerieren, auch wenn nur ein Kandidat inhaltlich betroffen ist.
   Wenn das Skript in der aktuellen Umgebung nicht ausfuehrbar ist, die JSON-Aenderungen trotzdem abschliessen und die Regeneration im Ergebnis vermerken.

9a. Suchradius-Seite neu generieren.
    Falls `suchradius.json` existiert oder aktualisiert wurde, zusaetzlich `python3 scripts/generate_scope_page.py <Kandidat>` ausfuehren (siehe [generate_scope_page.py](../../../scripts/generate_scope_page.py)). Ergebnis: `<Kandidat>/<slug>_suchradius.html`.

10. Ergebnis berichten.
   Fasse zusammen:
   - welche Branchen geaendert wurden
   - welche Firmen hinzugekommen, entfernt oder hochgestuft wurden
   - wie viele Jobs neu, entfernt oder aktualisiert wurden
   - ob das Dashboard neu generiert wurde
   - ob `suchradius.json` aktualisiert und die Suchradius-Seite neu generiert wurde

## Entscheidungsregeln

- CV und aktuelle Recherche haben Vorrang vor alten Listen.
- Relevanz geht vor Vollstaendigkeit. Lieber weniger, dafuer passgenaue Firmen und Jobs.
- Wenn der Bewerbername nicht eindeutig einem Ordner zugeordnet werden kann, nicht raten, sondern nachfragen.
- Wenn Quellen widerspruechliche Angaben liefern, bevorzuge die Original-Karriereseite des Unternehmens.
- Entferne bestehende Eintraege nicht nur deshalb, weil sie momentan keine offene Stelle haben, wenn das Unternehmen strategisch weiterhin gut passt.

## Ausgabequalitaet

- Schreibe gueltiges JSON im bestehenden Stil des Projekts.
- Behalte vorhandene deutsche Feldnamen und die aktuelle Datenform bei.
- Achte darauf, dass `standDatum` und recherchierte Aktualitaet zusammenpassen.
- Halte die Texte im Dashboard knapp, konkret und profilbezogen.

## Wenn etwas unklar ist

Frage den Nutzer gezielt nach:

- fehlendem oder mehrdeutigem CV-Pfad
- unklarem Kandidatennamen
- gewuenschtem Recherche-Fokus, wenn das Profil mehrere Richtungen gleich stark abdeckt