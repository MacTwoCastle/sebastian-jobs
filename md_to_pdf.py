"""
md_to_pdf.py – Konvertiert eine Markdown-Datei in eine PDF-Datei.
Renderer: Playwright (Headless Chromium) – identisches Ergebnis wie "Drucken via Chrome".

Verwendung:
    python md_to_pdf.py [eingabe.md] [ausgabe.pdf]
    Ohne Argumente: konvertiert EG_Retouren_Analyse.md

Einmalige Einrichtung (falls noch nicht installiert):
    1) Python 3 + pip installieren
    2) pip install playwright markdown
    3) playwright install chromium

Optional:
    CHROME_PATH setzen, um ein bestimmtes Chrome/Chromium-Binary zu verwenden.
"""

import sys
import pathlib
import tempfile
import re
import os
import markdown
from playwright.sync_api import sync_playwright

CSS = """
@page {
    size: A4;
}
body {
    font-family: Arial, sans-serif;
    font-size: 11pt;
    line-height: 1.5;
    color: #222;
}
h1 {
    font-size: 18pt;
    color: #003b6e;
    margin-top: 1em;
}
h2 {
    font-size: 14pt;
    color: #003b6e;
    border-bottom: 1px solid #003b6e;
    padding-bottom: 3px;
    margin-top: 1.5em;
}
h3 {
    font-size: 12pt;
    color: #333;
}
table {
    border-collapse: collapse;
    width: 100%;
    margin: 1em 0;
}
th, td {
    border: 1px solid #aaa;
    padding: 3px 6px;
    font-size: 9pt;
    line-height: 1.35;
}
th {
    background: #e8eef4;
}
tr {
    break-inside: avoid;
    page-break-inside: avoid;
}
code {
    font-family: "Courier New";
    background: #f4f4f4;
    padding: 1px 4px;
    font-size: 10pt;
}
ul, ol {
    margin-left: 0;
    padding-left: 2em;
}
li {
    padding-left: 0.3em;
    margin-bottom: 0.25em;
}
hr {
    border: none;
    border-top: 1px solid #ccc;
    margin: 1em 0;
}
blockquote {
    border-left: 3px solid #003b6e;
    margin-left: 0;
    padding-left: 1em;
    color: #555;
}
small {
    display: block;
    font-size: 9pt;
    break-inside: auto;
    page-break-inside: auto;
}
"""


UUID_RE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


def _is_setext_underline(line: str) -> bool:
    s = line.strip()
    return bool(s) and set(s) <= {"=", "-"}


def _sanitize_task_block(block_lines: list[str]) -> list[str]:
    entries = []
    i = 0

    while i < len(block_lines):
        s = block_lines[i].strip()

        if not s or s.isdigit() or UUID_RE.fullmatch(s):
            i += 1
            continue

        if s in {"incomplete", "complete"}:
            status = s
            j = i + 1
            while j < len(block_lines):
                nxt = block_lines[j].strip()
                if nxt and not nxt.isdigit() and not UUID_RE.fullmatch(nxt):
                    break
                j += 1

            if j < len(block_lines):
                text = block_lines[j].strip()
                if text not in {"incomplete", "complete"}:
                    entries.append((status, text))
                    i = j + 1
                    continue

            i += 1
            continue

        # Fallback for plain markdown lists without task status tokens
        entries.append((None, s))
        i += 1

    if not entries:
        return block_lines

    out = []
    current = None

    def flush_current():
        nonlocal current
        if not current:
            return

        symbol = "☐" if current["status"] != "complete" else "☑"
        status_text = "offen" if current["status"] != "complete" else "erledigt"
        out.append(f"- {symbol} {current['text']} (Status: {status_text})")

        if current["verantwortlich"]:
            out.append(f"  Verantwortlich: {current['verantwortlich']}")
        if current["zieltermin"]:
            out.append(f"  Zieltermin: {current['zieltermin']}")
        for detail in current["details"]:
            out.append(f"  {detail}")

        out.append("")
        current = None

    for status, text in entries:
        is_verantwortlich = text.startswith("**Verantwortlich:**")
        is_zieltermin = text.startswith("**Zieltermin:**")

        if is_verantwortlich and current:
            current["verantwortlich"] = text.replace("**Verantwortlich:**", "").strip()
            continue

        if is_zieltermin and current:
            current["zieltermin"] = text.replace("**Zieltermin:**", "").strip()
            continue

        flush_current()
        current = {
            "status": status or "incomplete",
            "text": text,
            "verantwortlich": None,
            "zieltermin": None,
            "details": [],
        }

    flush_current()

    # Keep one trailing blank line so the following heading starts a new section,
    # not a continuation of the last list item.
    while out and not out[-1].strip():
        out.pop()
    out.append("")

    return out


def sanitize_confluence_tasklist_artifacts(md_text: str) -> str:
    """Rewrites Confluence task-list export artifacts into readable markdown bullets.

    Typical artifact block in markdown export:
      17
      bb9dd50a-7737-4309-8b0a-85257ce6f6cc
      incomplete
      **Verantwortlich:** ...
    """
    lines = md_text.splitlines()

    start_idx = None
    for i in range(len(lines) - 1):
        if lines[i].strip().lower() == "aufgabenliste" and _is_setext_underline(lines[i + 1]):
            start_idx = i + 2
            break

    if start_idx is None:
        return md_text

    end_idx = len(lines)
    for j in range(start_idx, len(lines) - 1):
        if lines[j].strip() and _is_setext_underline(lines[j + 1]):
            end_idx = j
            break

    sanitized_block = _sanitize_task_block(lines[start_idx:end_idx])
    rebuilt = lines[:start_idx] + sanitized_block + lines[end_idx:]
    return "\n".join(rebuilt) + ("\n" if md_text.endswith("\n") else "")


def _fix_br_in_tables(md_text: str) -> str:
    """Ersetzt <br> in Tabellenzeilen (erkennbar am |) durch ein Leerzeichen,
    damit der tables-Parser nicht stolpert."""
    result = []
    for line in md_text.splitlines():
        if "|" in line:
            line = re.sub(r"<br\s*/?>", " ", line, flags=re.IGNORECASE)
        result.append(line)
    return "\n".join(result) + ("\n" if md_text.endswith("\n") else "")


def _get_browser_launch_kwargs() -> dict:
    """Returns launch kwargs with optional CHROME_PATH override.

    By default, Playwright uses its installed Chromium build. If CHROME_PATH
    is set and points to an existing executable, it is used instead.
    """
    chrome_path = os.environ.get("CHROME_PATH", "").strip()
    if chrome_path and pathlib.Path(chrome_path).exists():
        return {"executable_path": chrome_path}
    return {}


def convert(md_path: pathlib.Path, pdf_path: pathlib.Path):
    md_text = md_path.read_text(encoding="utf-8")
    md_text = sanitize_confluence_tasklist_artifacts(md_text)
    md_text = _fix_br_in_tables(md_text)
    html_body = markdown.markdown(
        md_text, extensions=["tables", "fenced_code", "nl2br"]
    )

    html = (
        "<!DOCTYPE html><html><head>"
        '<meta charset="utf-8">'
        f"<style>{CSS}</style>"
        f"</head><body>{html_body}</body></html>"
    )

    # Temporäre HTML-Datei schreiben, damit Playwright sie per file://-URL laden kann
    with tempfile.NamedTemporaryFile(
        suffix=".html", delete=False, mode="w", encoding="utf-8"
    ) as tmp:
        tmp.write(html)
        tmp_path = pathlib.Path(tmp.name)

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(**_get_browser_launch_kwargs())
            page = browser.new_page()
            page.goto(tmp_path.as_uri(), wait_until="networkidle")
            header_template = (
                '<div style="width:100%; font-family:Arial,sans-serif; font-size:9px;'
                ' color:#555; padding:0 1.5cm; box-sizing:border-box; display:flex;'
                ' justify-content:space-between;">'
                "<span>Privat - streng vertraulich!</span>"
                "<span>Quelle: Altersteilzeit</span>"
                "</div>"
            )
            footer_template = (
                '<div style="width:100%; font-family:Arial,sans-serif; font-size:9px;'
                ' color:#555; padding:0 1.5cm; box-sizing:border-box; display:flex;'
                ' justify-content:space-between;">'
                "<span>&#169; Dr. Steffen Steinhäuser</span>"
                '<span class="pageNumber"></span>'
                "</div>"
            )
            page.pdf(
                path=str(pdf_path),
                format="A4",
                print_background=True,
                display_header_footer=True,
                header_template=header_template,
                footer_template=footer_template,
                margin={"top": "2cm", "bottom": "2cm", "left": "1.5cm", "right": "1.5cm"},
            )
            browser.close()
    finally:
        tmp_path.unlink(missing_ok=True)

    size_kb = pdf_path.stat().st_size // 1024
    print(f"OK: {pdf_path}  ({size_kb} KB)")


if __name__ == "__main__":
    if len(sys.argv) >= 3:
        src = pathlib.Path(sys.argv[1])
        dst = pathlib.Path(sys.argv[2])
    elif len(sys.argv) == 2:
        src = pathlib.Path(sys.argv[1])
        dst = src.with_suffix(".pdf")
    else:
        base = pathlib.Path(__file__).parent
        src = base / "EG_Retouren_Analyse.md"
        dst = src.with_suffix(".pdf")

    if not src.exists():
        print(f"Datei nicht gefunden: {src}")
        sys.exit(1)

    print(f"Konvertiere: {src.name} -> {dst.name}")
    convert(src, dst)
