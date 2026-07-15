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
- `_template/generate_dashboard.ps1`

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

4. CV-basierte Suchhypothese bilden.
   Leite daraus die priorisierten Rollen, Fachgebiete, Branchen, Laender, Senioritaeten, Suchbegriffe und Ausschlusskriterien ab.

5. Neue Internet-Recherche durchfuehren.
   Recherchiere mit den Standardquellen nach:
   - passenden Branchen fuer das Profil
   - relevanten Zielunternehmen
   - aktuellen Stellenanzeigen
   - sinnvollen LinkedIn-Query-URLs

6. Daten aktualisieren.
   Aktualisiere standardmaessig im Modus `Ergaenzen`:
   - `profile.json`: nur Felder anpassen, die aus CV und neuer Recherche direkt betroffen sind, insbesondere `subtitle`, `searchStatus`, `standDatum`, `skills`, `branchen`, `laender`, Infobox-Texte und LinkedIn-Hinweise
   - `firmen.json`: neue relevante Firmen aufnehmen, veraltete Eintraege nur entfernen, wenn sie klar unpassend oder doppelt sind
   - `jobs.json`: neue aktuelle Stellen einpflegen, Duplikate vermeiden, offensichtliche Altlasten entfernen
   - `linkedin_queries.json`: Queries so aktualisieren, dass sie die Hauptrollen und Branchen des CV treffen

7. Qualitaet sichern.
   Pruefe vor dem Schreiben:
   - keine Dubletten bei Firmen oder Jobs
   - Match-Scores sind nachvollziehbar und relativ konsistent
   - Links zeigen direkt auf Suchseiten, Karriereportale oder Stellenanzeigen
   - Laender, Branchen und Senioritaet sind normalisiert

8. Dashboard neu generieren.
   Nach den JSON-Aenderungen das Dashboard aus den Daten neu erzeugen, bevorzugt ueber [../../../_template/generate_dashboard.ps1](../../../_template/generate_dashboard.ps1).
   Wenn PowerShell in der aktuellen Umgebung nicht sinnvoll verfuegbar ist, die JSON-Aenderungen trotzdem abschliessen und die Regeneration im Ergebnis vermerken.

9. Ergebnis berichten.
   Fasse zusammen:
   - welche Branchen geaendert wurden
   - welche Firmen hinzugekommen, entfernt oder hochgestuft wurden
   - wie viele Jobs neu, entfernt oder aktualisiert wurden
   - ob das Dashboard neu generiert wurde

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