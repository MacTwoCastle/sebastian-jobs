[CmdletBinding()]
param(
    [string]$InputDir = ".",
    [string]$OutputDir = ".\\ki-ready",
    [string]$OcrLanguages = "deu+eng",
    [int]$MinExtractedChars = 400,
    [int]$ChunkChars = 4500,
    [switch]$ForceOcr
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-Tool {
    param([Parameter(Mandatory = $true)][string]$Name)

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$IgnoreExitCode
    )

    & $FilePath @Arguments
    $exitCode = $LASTEXITCODE
    if (-not $IgnoreExitCode -and $exitCode -ne 0) {
        throw "Befehl fehlgeschlagen: $FilePath $($Arguments -join ' ') (ExitCode: $exitCode)"
    }
}

function Get-NonWhitespaceCharCount {
    param([Parameter(Mandatory = $true)][string]$Text)

    return ([regex]::Matches($Text, "\S")).Count
}

function ConvertTo-CleanText {
    param([Parameter(Mandatory = $true)][string]$RawText)

    $text = $RawText

    # Seitenumbrueche von pdftotext entfernen.
    $text = $text -replace "`f", "`n"

    # Silbentrennung ueber Zeilenende zusammenziehen (z. B. "Doku-\nment" -> "Dokument").
    $text = $text -replace "(?m)([\p{L}])-\r?\n([\p{L}])", '$1$2'

    # Mehrfache Leerzeichen reduzieren, aber einfache Zeilenumbrueche erhalten.
    $text = $text -replace "[ \t]{2,}", " "

    # Sehr haeufige Artefakte: reine Seitenzahl-Zeilen entfernen.
    $text = $text -replace "(?m)^\s*\d{1,4}\s*$", ""

    # Maximal 2 aufeinanderfolgende Leerzeilen behalten.
    $text = $text -replace "(\r?\n){3,}", "`r`n`r`n"

    return $text.Trim()
}

function New-Chunks {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$BaseName,
        [Parameter(Mandatory = $true)][string]$ChunkDir,
        [Parameter(Mandatory = $true)][int]$MaxChars,
        [Parameter(Mandatory = $true)][string]$SourcePdf
    )

    if (-not (Test-Path -LiteralPath $ChunkDir)) {
        New-Item -ItemType Directory -Path $ChunkDir | Out-Null
    }

    Get-ChildItem -Path $ChunkDir -Filter ("{0}.chunk-*.md" -f $BaseName) -File -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    $paragraphs = $Text -split "(\r?\n){2,}"
    $buffer = ""
    $chunkIndex = 1
    $writtenFiles = @()

    foreach ($p in $paragraphs) {
        $paragraph = $p.Trim()
        if ([string]::IsNullOrWhiteSpace($paragraph)) {
            continue
        }

        $candidate = if ([string]::IsNullOrWhiteSpace($buffer)) { $paragraph } else { "$buffer`r`n`r`n$paragraph" }

        if ($candidate.Length -le $MaxChars) {
            $buffer = $candidate
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($buffer)) {
            $chunkPath = Join-Path $ChunkDir ("{0}.chunk-{1:D3}.md" -f $BaseName, $chunkIndex)
            $content = @(
                "---",
                "source: $SourcePdf",
                "chunk: $chunkIndex",
                "---",
                "",
                $buffer
            ) -join "`r`n"
            [System.IO.File]::WriteAllText($chunkPath, $content, [System.Text.Encoding]::UTF8)
            $writtenFiles += $chunkPath
            $chunkIndex++
        }

        if ($paragraph.Length -gt $MaxChars) {
            $start = 0
            while ($start -lt $paragraph.Length) {
                $len = [Math]::Min($MaxChars, $paragraph.Length - $start)
                $part = $paragraph.Substring($start, $len)
                $chunkPath = Join-Path $ChunkDir ("{0}.chunk-{1:D3}.md" -f $BaseName, $chunkIndex)
                $content = @(
                    "---",
                    "source: $SourcePdf",
                    "chunk: $chunkIndex",
                    "---",
                    "",
                    $part
                ) -join "`r`n"
                [System.IO.File]::WriteAllText($chunkPath, $content, [System.Text.Encoding]::UTF8)
                $writtenFiles += $chunkPath
                $chunkIndex++
                $start += $len
            }
            $buffer = ""
        }
        else {
            $buffer = $paragraph
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($buffer)) {
        $chunkPath = Join-Path $ChunkDir ("{0}.chunk-{1:D3}.md" -f $BaseName, $chunkIndex)
        $content = @(
            "---",
            "source: $SourcePdf",
            "chunk: $chunkIndex",
            "---",
            "",
            $buffer
        ) -join "`r`n"
        [System.IO.File]::WriteAllText($chunkPath, $content, [System.Text.Encoding]::UTF8)
        $writtenFiles += $chunkPath
    }

    return $writtenFiles
}

$hasPandoc = Test-Tool -Name "pandoc"
$hasPdfToText = Test-Tool -Name "pdftotext"
$hasOcrMyPdf = Test-Tool -Name "ocrmypdf"

if (-not $hasPandoc) {
    throw "pandoc wurde nicht gefunden. Bitte zuerst pandoc installieren."
}
if (-not $hasPdfToText) {
    throw "pdftotext wurde nicht gefunden. Bitte Poppler/Xpdf installieren (siehe README-Pipeline.md)."
}

$inputPath = (Resolve-Path $InputDir).Path
if (-not (Test-Path -LiteralPath $inputPath)) {
    throw "InputDir existiert nicht: $InputDir"
}

$pdfFiles = Get-ChildItem -Path $inputPath -Filter "*.pdf" -File
if ($pdfFiles.Count -eq 0) {
    Write-Host "Keine PDF-Dateien gefunden in: $inputPath"
    exit 0
}

$txtDir = Join-Path $OutputDir "01_txt_raw"
$cleanDir = Join-Path $OutputDir "02_txt_clean"
$mdDir = Join-Path $OutputDir "03_markdown"
$chunkDir = Join-Path $OutputDir "04_chunks"
$ocrDir = Join-Path $OutputDir "_ocr"

foreach ($d in @($OutputDir, $txtDir, $cleanDir, $mdDir, $chunkDir, $ocrDir)) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

$report = New-Object System.Collections.Generic.List[object]

foreach ($pdf in $pdfFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($pdf.Name)
    $safeBase = ($baseName -replace "[^A-Za-z0-9._-]", "_")

    $rawTxtPath = Join-Path $txtDir ("$safeBase.txt")
    $cleanTxtPath = Join-Path $cleanDir ("$safeBase.clean.txt")
    $mdPath = Join-Path $mdDir ("$safeBase.md")

    $sourceForExtraction = $pdf.FullName
    $ocrApplied = $false

    Write-Host "Verarbeite: $($pdf.Name)"

    Invoke-External -FilePath "pdftotext" -Arguments @("-layout", "-enc", "UTF-8", $sourceForExtraction, $rawTxtPath)

    $rawText = [System.IO.File]::ReadAllText($rawTxtPath, [System.Text.Encoding]::UTF8)
    $charCount = Get-NonWhitespaceCharCount -Text $rawText

    if (($ForceOcr -or $charCount -lt $MinExtractedChars) -and $hasOcrMyPdf) {
        Write-Host "  -> Wenig Text erkannt, OCR wird ausgefuehrt"
        $ocrPdfPath = Join-Path $ocrDir ("$safeBase.ocr.pdf")
        Invoke-External -FilePath "ocrmypdf" -Arguments @("--skip-text", "-l", $OcrLanguages, $pdf.FullName, $ocrPdfPath)
        $sourceForExtraction = $ocrPdfPath
        $ocrApplied = $true

        Invoke-External -FilePath "pdftotext" -Arguments @("-layout", "-enc", "UTF-8", $sourceForExtraction, $rawTxtPath)
        $rawText = [System.IO.File]::ReadAllText($rawTxtPath, [System.Text.Encoding]::UTF8)
        $charCount = Get-NonWhitespaceCharCount -Text $rawText
    }
    elseif (($ForceOcr -or $charCount -lt $MinExtractedChars) -and -not $hasOcrMyPdf) {
        Write-Warning "OCR erforderlich, aber ocrmypdf ist nicht installiert: $($pdf.Name)"
    }

    $cleanText = ConvertTo-CleanText -RawText $rawText
    [System.IO.File]::WriteAllText($cleanTxtPath, $cleanText, [System.Text.Encoding]::UTF8)

    Invoke-External -FilePath "pandoc" -Arguments @(
        $cleanTxtPath,
        "-f", "markdown",
        "-t", "gfm",
        "--wrap=none",
        "-o", $mdPath
    )

    $chunkFiles = @(New-Chunks -Text $cleanText -BaseName $safeBase -ChunkDir $chunkDir -MaxChars $ChunkChars -SourcePdf $pdf.Name)

    $report.Add([pscustomobject]@{
        pdf = $pdf.Name
        ocr_applied = $ocrApplied
        non_whitespace_chars = $charCount
        txt_raw = $rawTxtPath
        txt_clean = $cleanTxtPath
        markdown = $mdPath
        chunks = $chunkFiles.Count
    }) | Out-Null
}

$reportPath = Join-Path $OutputDir "report.json"
$report | ConvertTo-Json -Depth 4 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Fertig. Ergebnisordner: $OutputDir"
Write-Host "Report: $reportPath"
