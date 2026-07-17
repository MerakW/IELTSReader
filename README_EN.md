# IELTSReader 1.5.0

A native macOS reader for IELTS practice PDFs, designed to turn paper-style PDF material into a focused computer-based reading workspace.

GitHub: https://github.com/MerakW/IELTSReader

Download: https://github.com/MerakW/IELTSReader/releases/latest

## Requirements

- macOS 13.0 or later
- Apple Silicon or Intel Mac

## Download

The latest release provides:

```text
IELTSReader-1.5.0-Universal.app.zip
IELTSReader-1.5.0-Apple-Silicon.app.zip
```

The Universal build is recommended for most users.

## Features

- Import local PDF practice files
- Split Passage and Questions into separate PDF panes
- Enter page ranges directly for each pane
- Answer with text, multiple choice, or True / False / Not Given
- Custom question numbers with automatic numbering after edits
- Text-selection based highlight, underline, strikeout, and cleanup
- Timer and Strict Mode for focused practice
- Save and load practice sessions
- Copy answers as text or preview and export them as an image

## Usage

```sh
./make_app.sh
open .build/IELTSReader.app
```

## Workflow

1. Click `Import` and choose a PDF.
2. Enter the Passage and Questions page ranges.
3. Fill answers in the right panel.
4. Select PDF text before applying highlight, underline, or strikeout.
5. Save the session or export answers as `.txt` / `.png`.

## Credit

Made by Merak.
