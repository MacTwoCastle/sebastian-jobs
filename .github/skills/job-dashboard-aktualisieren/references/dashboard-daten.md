# Dashboard-Datenstruktur

Diese Referenz beschreibt die vorhandene JSON-Struktur fuer ein Kandidaten-Dashboard in diesem Repository.

## profile.json

Pfad: `<Kandidat>/data/profile.json`

Typische Felder:

- `name`: Vollname des Bewerbers
- `slug`: Kurzname fuer generierte Dateinamen
- `subtitle`: Kurzprofil im Dashboard-Header
- `searchStatus`: aktueller Recherche- oder Bewerbungsstatus
- `standDatum`: Stichtag im Format `TT.MM.JJJJ`
- `skills`: Liste fachlicher Schlagwoerter
- `branchen`: Zielbranchen fuer Firmen- und Jobfilter
- `laender`: Zielmaerkte oder Suchlaender
- `firmenInfobox`: HTML-Text fuer die Firmenansicht
- `jobsInfobox`: HTML-Text fuer die Jobansicht
- `linkedinKeywordsTipp`: Kurztext mit empfohlenen Suchbegriffen
- `linkedinCompaniesTipp`: Kurztext mit empfohlenen Zielfirmen

Aktualisierungsregeln:

- `branchen` nur mit CV- oder Recherchebezug erweitern
- `standDatum` bei jeder inhaltlichen Rechercheaktualisierung anheben
- Infoboxen nicht generisch schreiben, sondern immer mit Bezug auf Profil und Suchlogik

## firmen.json

Pfad: `<Kandidat>/data/firmen.json`

Erwartete Felder je Eintrag:

- `name`
- `branche`
- `land`
- `laender`: Array normalisierter Laendernamen
- `ma`: numerischer Mitarbeiterwert
- `ma_label`: Anzeigeformat
- `umsatz`: Anzeigeformat
- `match`: Ganzzahl, typischerweise 1 bis 5
- `portal`: Karriere- oder Jobportal-Link
- `groesse`: `klein`, `mittel` oder `gross`

Bewertungslogik fuer `match`:

- `5`: sehr starke Uebereinstimmung von Produktwelt, Rolle und CV
- `4`: klar passend, aber nicht Kernziel
- `3`: brauchbar, jedoch mit spuerbaren Abstrichen
- `1-2`: nur verwenden, wenn bewusst als Randoption aufgenommen

## jobs.json

Pfad: `<Kandidat>/data/jobs.json`

Erwartete Felder je Eintrag:

- `title`
- `company`
- `ort`
- `land`
- `branche`
- `remote`: etwa `Remote`, `Hybrid`, `Onsite`
- `sprache`
- `veroeffentlicht`: menschenlesbarer Text
- `alter_tage`: numerischer Alterswert fuer Filter
- `match`: Ganzzahl, typischerweise 1 bis 5
- `level`: etwa `Einsteiger`, `Junior (1-3 J.)`, `Senior`
- `anforderungen`: verdichtete Kurzbewertung der Anforderungen
- `link`: Direktlink zur Stelle oder Suchseite
- `quelle`: Quelle wie LinkedIn, StepStone, Indeed, XING oder Careers

Aktualisierungsregeln:

- keine doppelten Stellen fuer gleiche Firma und gleichen Titel
- moeglichst Direktlinks statt Startseiten
- `alter_tage` konsistent zur Textangabe halten
- Jobtexte komprimieren, aber CV-relevante Begriffe sichtbar lassen

## linkedin_queries.json

Pfad: `<Kandidat>/data/linkedin_queries.json`

Erwartete Felder je Eintrag:

- `title`
- `description`
- `url`

Aktualisierungsregeln:

- Queries muessen aus dem CV ableitbar sein
- unterschiedliche Stoerichtungen als getrennte Queries modellieren
- Titel und Beschreibung knapp und fuer die Dashboard-Ansicht lesbar halten

## Dubletten und Konsistenz

- Firmen nach `name` deduplizieren
- Jobs primaer nach Kombination aus `company`, `title` und `ort` deduplizieren
- Schreibweisen fuer Branchen, Laender, Remote-Modell und Level innerhalb einer Datei normalisieren