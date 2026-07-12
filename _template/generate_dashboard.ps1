<#
.SYNOPSIS
  Generiert ein Job-Dashboard-HTML für einen Kandidaten aus seinen Daten-JSON-Dateien.

.DESCRIPTION
  Liest _template/dashboard_template.html und ersetzt den DATA-Abschnitt
  mit den kandidatenspezifischen Daten aus <Kandidat>/data/*.json.
  Generiert zusätzlich manifest.json, sw.js und index.html.

.PARAMETER Candidate
  Ordnername des Kandidaten (z.B. "Sebastian" oder "Ulf").

.EXAMPLE
  .\generate_dashboard.ps1 -Candidate Sebastian
  .\generate_dashboard.ps1 -Candidate Ulf

.NOTES
  Voraussetzung: <Kandidat>/data/profile.json, firmen.json, jobs.json, linkedin_queries.json
  Der _template/-Ordner befindet sich eine Ebene über dem Kandidaten-Ordner.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Candidate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Pfade ---
$templateDir   = $PSScriptRoot
$baseDir       = Split-Path $templateDir -Parent
$candidateDir  = Join-Path $baseDir $Candidate
$dataDir       = Join-Path $candidateDir "data"
$templateFile  = Join-Path $templateDir "dashboard_template.html"

# --- Validierung ---
if (-not (Test-Path $candidateDir))  { throw "Kandidaten-Ordner nicht gefunden: $candidateDir" }
if (-not (Test-Path $dataDir))        { throw "Data-Ordner nicht gefunden: $dataDir" }
if (-not (Test-Path $templateFile))   { throw "Template nicht gefunden: $templateFile" }

foreach ($f in @("profile.json","firmen.json","jobs.json","linkedin_queries.json")) {
    if (-not (Test-Path (Join-Path $dataDir $f))) {
        throw "Datei fehlt: $dataDir\$f"
    }
}

# --- Daten einlesen (explizit UTF-8) ---
$profileJson  = [System.IO.File]::ReadAllText((Join-Path $dataDir "profile.json"),          [System.Text.Encoding]::UTF8)
$firmenJson   = [System.IO.File]::ReadAllText((Join-Path $dataDir "firmen.json"),            [System.Text.Encoding]::UTF8)
$jobsJson     = [System.IO.File]::ReadAllText((Join-Path $dataDir "jobs.json"),              [System.Text.Encoding]::UTF8)
$linkedinJson = [System.IO.File]::ReadAllText((Join-Path $dataDir "linkedin_queries.json"),  [System.Text.Encoding]::UTF8)

$profile = $profileJson | ConvertFrom-Json
$slug    = $profile.slug

# --- Template einlesen ---
$template = [System.IO.File]::ReadAllText($templateFile, [System.Text.Encoding]::UTF8)

# --- Neuen DATA-Abschnitt bauen (String-Konkatenation, kein Here-String – vermeidet $-Interpolation in JSON) ---
$startMarker = '// ===== DATA: CANDIDATE-SPECIFIC (auto-generated - do not edit manually) ====='
$endMarker   = '// ===== END DATA SECTION ====='

$nl = [System.Environment]::NewLine
$newDataSection = $startMarker + $nl
$newDataSection += "const PROFILE = " + $profileJson  + ";" + $nl
$newDataSection += "const firmenData = " + $firmenJson + ";" + $nl
$newDataSection += "const jobsData = " + $jobsJson     + ";" + $nl
$newDataSection += "const linkedinQueries = " + $linkedinJson + ";" + $nl
$newDataSection += $endMarker

# --- DATA-Abschnitt im Template ersetzen ---
$startIdx = $template.IndexOf($startMarker)
$endIdx   = $template.IndexOf($endMarker)

if ($startIdx -lt 0) { throw "Start-Marker nicht gefunden im Template." }
if ($endIdx   -lt 0) { throw "End-Marker nicht gefunden im Template." }

$endIdx += $endMarker.Length
$newContent = $template.Substring(0, $startIdx) + $newDataSection + $template.Substring($endIdx)

# --- Dashboard-HTML speichern ---
$outputFile = Join-Path $candidateDir ($slug + "_jobs_dashboard.html")
[System.IO.File]::WriteAllText($outputFile, $newContent, [System.Text.Encoding]::UTF8)
Write-Host ("[OK] Dashboard:   " + $outputFile)

# --- manifest.json generieren ---
$firstName = ($profile.name -split ' ')[0]
$manifest = [ordered]@{
    name             = "Job-Dashboard __ " + $profile.name
    short_name       = "Jobs __ " + $firstName
    description      = $profile.subtitle
    start_url        = "./" + $slug + "_jobs_dashboard.html"
    display          = "standalone"
    background_color = "#f4f7fb"
    theme_color      = "#1a3a5c"
    orientation      = "any"
    icons            = @(
        [ordered]@{ src = "icon.svg"; sizes = "any"; type = "image/svg+xml"; purpose = "any"      },
        [ordered]@{ src = "icon.svg"; sizes = "any"; type = "image/svg+xml"; purpose = "maskable" }
    )
}
$manifestJson = $manifest | ConvertTo-Json -Depth 5 | ForEach-Object { $_ -replace '__', '–' }
[System.IO.File]::WriteAllText((Join-Path $candidateDir "manifest.json"), $manifestJson, [System.Text.Encoding]::UTF8)
Write-Host "[OK] manifest.json"

$swContent = "const CACHE_NAME = 'jobs-" + $slug + "-v1';" + $nl
$swContent += "const ASSETS = [" + $nl
$swContent += "  './" + $slug + "_jobs_dashboard.html'," + $nl
$swContent += "  './manifest.json'," + $nl
$swContent += "  './icon.svg'" + $nl
$swContent += "];" + $nl + $nl
$swContent += @'
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(resp => {
        const copy = resp.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
        return resp;
      });
    })
  );
});
'@

[System.IO.File]::WriteAllText((Join-Path $candidateDir "sw.js"), $swContent, [System.Text.Encoding]::UTF8)
Write-Host "[OK] sw.js"

# --- index.html generieren ---
$indexContent = "<!DOCTYPE html>" + $nl
$indexContent += "<html><head><meta charset=""UTF-8"">" + $nl
$indexContent += "<meta http-equiv=""refresh"" content=""0; url=" + $slug + "_jobs_dashboard.html"">" + $nl
$indexContent += "<title>Job-Dashboard __ " + $profile.name + "</title>" + $nl
$indexContent += "</head><body></body></html>" + $nl
[System.IO.File]::WriteAllText((Join-Path $candidateDir "index.html"), $indexContent, [System.Text.Encoding]::UTF8)
Write-Host "[OK] index.html"

Write-Host ""
Write-Host ("  Fertig! Dashboard fuer " + $profile.name + " generiert.")
Write-Host ("  Oeffnen: " + $outputFile)
