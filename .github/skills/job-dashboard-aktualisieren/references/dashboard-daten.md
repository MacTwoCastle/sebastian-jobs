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

Personalvermittler/Headhunter (z. B. Vesterling AG, HAPEKO, MEYHEADHUNTER, conQuaesso, recruitIT, DIS AG, HIBA) gehoeren **nicht** in firmen.json, da der tatsaechliche Arbeitgeber in der Anzeige meist anonym bleibt und es sich nicht um ein recherchierbares Zielunternehmen handelt. Stattdessen werden solche Stellen in jobs.json ueber das Feld `vermittler` gekennzeichnet (siehe unten).

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
- `vermittler`: optional, `true` wenn die Stelle ueber eine Personalberatung/einen Headhunter inseriert ist und der tatsaechliche Arbeitgeber anonym bleibt (Feld weglassen oder `false`, wenn `company` der reale Arbeitgeber ist). Das Dashboard zeigt dafuer automatisch ein Hinweis-Badge mit Tooltip ("🕵️ Vermittlung") neben dem Firmennamen an.
- `linkOffline`: optional, `true` setzen, wenn beim Aufrufen von `link` festgestellt wurde, dass die Stellenanzeige nicht mehr online ist (z. B. StepStone/Indeed zeigt "Stelle nicht mehr verfuegbar"). Das Dashboard zeigt dafuer ein Warn-Badge ("⚠️ ggf. offline") neben dem Jobtitel. Zusaetzlich erzeugt das Dashboard automatisch einen Fallback-Link "🏢 Firmen-Karriereseite" unter dem Bewerben-Button, sobald `company` per Name auf einen Eintrag in `firmen.json` matcht und dessen `portal` sich vom Job-`link` unterscheidet – das passiert unabhaengig von `linkOffline` fuer jede Stelle, damit Bewerber immer eine Alternative haben, falls ein Stellenlink (typischerweise bei StepStone) inzwischen abgelaufen ist.
- `herkunft`: optional, `"abschlussbasiert"` setzen, wenn die Stelle nicht ueber eine der spezialisierten Zielrollen, sondern ueber eine breite, abschlussorientierte Suche (z. B. generischer Titel + Abschlussanforderung wie "M.Sc. Maschinenbau") gefunden wurde. Feld weglassen (Standard = rollenspezifisch), wenn die Stelle ueber eine Zielrollen-Suchbegriff gefunden wurde. Das Dashboard zeigt dafuer ein Hinweis-Badge ("🎓 Abschlussbasiert") und bietet einen eigenen Filter ("Herkunft") im Jobs-Tab.
- `anforderungen`: verdichtete Kurzbewertung der Anforderungen
- `link`: Direktlink zur Stelle oder Suchseite
- `quelle`: Quelle wie LinkedIn, StepStone, Indeed, XING oder Careers

Aktualisierungsregeln:

- keine doppelten Stellen fuer gleiche Firma und gleichen Titel
- moeglichst Direktlinks statt Startseiten
- `alter_tage` konsistent zur Textangabe halten
- Jobtexte komprimieren, aber CV-relevante Begriffe sichtbar lassen
- Stellen von Personalvermittlern/Headhuntern (Executive Search, Personalkontor etc.) mit `"vermittler": true` markieren, statt die Agentur als eigenstaendige Firma in firmen.json zu fuehren
- Beim Recherchieren neuer/bestehender Jobs den `link` moeglichst pruefen; zeigt die Quelle (typischerweise StepStone) eine "Stelle nicht mehr verfuegbar"-Meldung, den Eintrag nicht loeschen, sondern `"linkOffline": true` setzen, damit Bewerber gewarnt werden und automatisch den Fallback-Link zur Firmen-Karriereseite sehen
- Ergaenzend zur rollenspezifischen Suche gezielt auch nach generischen, abschlussorientierten Stellenanzeigen recherchieren (Titel wie "Entwicklungsingenieur", "Konstrukteur", "Projektingenieur" mit Anforderung des passenden Studienabschlusses); Treffer mit `"herkunft": "abschlussbasiert"` markieren, damit sie im Dashboard erkennbar bleiben

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

## herleitung.json

Pfad: `<Kandidat>/data/herleitung.json`

Optionale Datei fuer den Dashboard-Tab "🧭 Herleitung". Sie macht transparent, wie aus dem CV ein Suchprofil abgeleitet wurde und wie dieses Suchprofil die Recherche zu Branchen, Firmen, Jobs und LinkedIn-Queries gesteuert hat. Fehlt die Datei, zeigt das Dashboard einen Hinweis, dass noch keine Herleitung vorliegt (kein Fehler).

Erwartete Struktur:

- `cvQuellen`: Liste der ausgewerteten Dateinamen (CV, Zeugnisse etc.)
- `cvFakten`: Array von `{ "kategorie": "...", "punkte": ["...", ...] }` – z. B. Kategorien "Ausbildung", "Berufserfahrung", "Methoden & Skills", "Zusatzqualifikationen"
- `suchprofil`: Array von `{ "dimension": "...", "werte": ["...", ...], "begruendung": "..." }`. Uebliche Dimensionen: `Zielrollen`, `Branchen`, `Länder`, `Senioritätsstufe`, `Suchbegriffe`, `Ausschlusskriterien`. Die Werte der Dimension `Branchen` sollten mit `profile.branchen` sowie den `branche`-Werten in `firmen.json`/`jobs.json` uebereinstimmen, da das Dashboard daraus live Firmen-/Job-Zaehler pro Branche berechnet und Klick-Sprung-Filter anbietet.
- `rechercheSchritte`: Array von Kurztexten, die den Ablauf CV-Analyse -> Suchprofil -> Internet-Recherche -> Dashboard-Daten in Prosa zusammenfassen

Aktualisierungsregeln:

- Bei jeder inhaltlichen Aktualisierung (neues CV, neue Recherche) `herleitung.json` synchron mit `profile.branchen`, `firmen.json` und `jobs.json` halten
- `begruendung` je Suchprofil-Dimension immer konkret auf CV-Fakten oder Rechercheergebnisse beziehen, nicht generisch formulieren
- Datei ist optional; bei fehlendem oder unklarem CV lieber weglassen/unveraendert lassen statt zu raten

## suchradius.json

Pfad: `<Kandidat>/data/suchradius.json`

Optionale Datei fuer die separate Seite `<Kandidat>/<slug>_suchradius.html` ("Suchradius"). Sie macht transparent, wie breit der Firmen-Suchraum tatsaechlich war, auch fuer Firmen ohne aktuellen Treffer. Sie ist bewusst getrennt von `firmen.json`, damit das bestehende Dashboard (Firmenuebersicht, Matching-Logik) unveraendert bleibt.

Erwartete Struktur:

- `standDatum`: Stichtag der Recherche, Format `TT.MM.JJJJ`
- `durchsuchtePortale`: Array der genutzten Quellen, z. B. `["LinkedIn Jobs", "StepStone", "Indeed", "XING", "Firmen-Karriereseiten"]`
- `kategorien`: Array von `{ "name": "...", "firmen": [ { "name": "...", "status": "treffer" | "beobachtet", "portal": "..." } ] }`

Regeln:

- `kategorien[].name` sollte moeglichst deckungsgleich mit den Werten aus `profile.branchen` sein (individuell je Kandidat abgeleitet), damit Zaehler konsistent wirken.
- `status: "treffer"` fuer Firmen, die auch in `firmen.json` mit Match-Score gelistet sind.
- `status: "beobachtet"` fuer Firmen, die im Rahmen der Kategorien-Breite recherchiert wurden, aber aktuell keinen passenden Treffer liefern. `portal` ist hier optional; nur eintragen, wenn die Karriereseite verifiziert wurde, nicht raten.
- Ziel ist methodische Breite: bei jeder Recherche moeglichst jede Kategorie aus `profile.branchen` mit mehreren Firmen (Treffer + beobachtet) abdecken, nicht nur die Kategorien mit bereits bekannten Treffern.
- Datei ist optional; bei fehlender Datei zeigt die Suchradius-Seite einen Hinweis, dass noch keine Daten vorliegen.

## Dubletten und Konsistenz

- Firmen nach `name` deduplizieren
- Jobs primaer nach Kombination aus `company`, `title` und `ort` deduplizieren
- Schreibweisen fuer Branchen, Laender, Remote-Modell und Level innerhalb einer Datei normalisieren