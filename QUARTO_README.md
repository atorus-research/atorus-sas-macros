# Converting Doxygen XML to Quarto Documentation

This guide explains how to automatically convert the Doxygen XML documentation into a Quarto book.

## Overview

The `xml_to_qmd.py` script parses the Doxygen XML output and generates individual Quarto markdown (.qmd) files for each SAS macro, which can be compiled into a beautiful, searchable Quarto book.

## Prerequisites

1. **Python 3.6+** (usually pre-installed on macOS)
2. **Quarto** - Install from https://quarto.org/docs/get-started/

### Installing Quarto

**macOS:**
```bash
brew install quarto
```

**Or download from:**
https://quarto.org/docs/get-started/

## Quick Start

### 1. Generate Doxygen XML (if not already done)

```bash
doxygen Doxyfile
```

This creates XML files in `docs/xml/`

### 2. Run the Conversion Script

**Basic usage:**
```bash
python xml_to_qmd.py
```

**With book configuration:**
```bash
python xml_to_qmd.py --create-book-config
```

**Custom directories:**
```bash
python xml_to_qmd.py --xml-dir docs/xml --output-dir quarto/macros --create-book-config
```

### 3. Build the Quarto Book

```bash
cd quarto
quarto render
```

The rendered book will be in `quarto/_book/`

### 4. Preview the Book

```bash
cd quarto
quarto preview
```

This opens a live-preview browser window.

## Generated Structure

After running `xml_to_qmd.py --create-book-config`, you'll have:

```
quarto/
├── _quarto.yml           # Book configuration
├── index.qmd             # Book homepage
└── macros/               # Individual macro documentation
    ├── autoexec.qmd
    ├── xcdtc2dt.qmd
    ├── xcdtcdy.qmd
    ├── kdident.qmd
    └── ...                # One .qmd per macro
```

## Quarto Output Formats

### HTML (Default)

```bash
quarto render
```

Creates an interactive HTML book with:
- Searchable content
- Navigation sidebar
- Responsive design
- Code highlighting

### PDF

Edit `_quarto.yml` to add PDF format:

```yaml
format:
  html:
    theme: cosmo
  pdf:
    documentclass: scrbook
```

Then render:
```bash
quarto render --to pdf
```

### Word (DOCX)

```yaml
format:
  html:
    theme: cosmo
  docx:
    toc: true
```

```bash
quarto render --to docx
```

## Generated QMD Format

Each macro's .qmd file includes:

```markdown
---
title: "xcdtc2dt"
author: "Atorus Research"
date: "19FEB2021"
---

## Description

Convert character --DTC variable into analysis -DT -TM -DTM

## Parameters

**`dtcdate`**

: Name of --DTC variable (Required)

  *Required:* Yes

**`prefix`**

: Prefix for numeric analysis variables

  *Required:* No

  *Default:* `a`

## Returns

Creates &prefix.dtm, &prefix.dt, &prefix.tm variables

## Examples

```sas
%xcdtc2dt(aestdtc, prefix=ast, refdate=trtsdt);
```

## Remarks

Additional notes...
```

## Customizing the Book

### Change Theme

Edit `_quarto.yml`:

```yaml
format:
  html:
    theme: cosmo  # Options: cosmo, flatly, darkly, etc.
```

Available themes: https://quarto.org/docs/output-formats/html-themes.html

### Add Logo

```yaml
format:
  html:
    theme: cosmo
    logo: logo.png
```

### Customize Navigation

Edit the `chapters` section in `_quarto.yml`:

```yaml
book:
  title: "My Custom Title"
  chapters:
    - index.qmd
    - part: "Custom Section"
      chapters:
        - macros/macro1.qmd
        - macros/macro2.qmd
```

### Add Custom CSS

```yaml
format:
  html:
    theme: cosmo
    css: styles.css
```

## Script Options

### Command Line Arguments

```bash
python xml_to_qmd.py --help
```

**Options:**
- `--xml-dir` - Directory with Doxygen XML files (default: `docs/xml`)
- `--output-dir` - Output directory for .qmd files (default: `quarto/macros`)
- `--create-book-config` - Generate `_quarto.yml` and `index.qmd`

### Example Workflows

**Regenerate everything:**
```bash
# 1. Generate fresh Doxygen XML
doxygen Doxyfile

# 2. Convert to Quarto
python xml_to_qmd.py --create-book-config

# 3. Build book
cd quarto && quarto render
```

**Update single macro:**
```bash
# Just re-run conversion (faster)
python xml_to_qmd.py
cd quarto && quarto render
```

## Publishing the Book

### GitHub Pages

1. Add to `_quarto.yml`:

```yaml
project:
  type: book
  output-dir: _book

book:
  title: "Atorus SAS Macros"
  repo-url: https://github.com/your-org/atorus-sas-macros
  repo-actions: [issue]
```

2. Render and push:

```bash
quarto render
# Then commit and push _book/ directory
```

3. Configure GitHub Pages to use the `_book` directory

### Deploy to RStudio Connect or Posit Connect

```bash
quarto publish connect
```

### Self-hosted

Simply copy the `_book/` directory to your web server.

## Integration with Doxygen Workflow

### Automated Pipeline

Create a script `generate_docs.sh`:

```bash
#!/bin/bash
echo "Generating documentation..."

# Step 1: Generate Doxygen XML
echo "→ Running Doxygen..."
doxygen Doxyfile

# Step 2: Convert to Quarto
echo "→ Converting XML to Quarto..."
python xml_to_qmd.py --create-book-config

# Step 3: Build Quarto book
echo "→ Building Quarto book..."
cd quarto && quarto render

echo "✓ Documentation generated in quarto/_book/"
```

Make it executable:
```bash
chmod +x generate_docs.sh
./generate_docs.sh
```

### CI/CD with GitHub Actions

Create `.github/workflows/docs.yml`:

```yaml
name: Build Documentation

on:
  push:
    branches: [main]

jobs:
  build-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install Doxygen
        run: sudo apt-get install doxygen

      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.x'

      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2

      - name: Generate Doxygen XML
        run: doxygen Doxyfile

      - name: Convert to Quarto
        run: python xml_to_qmd.py --create-book-config

      - name: Render Quarto Book
        run: |
          cd quarto
          quarto render

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./quarto/_book
```

## Troubleshooting

### "No module named xml.etree"

This should not happen (part of Python stdlib), but if it does:
```bash
python3 xml_to_qmd.py
```

### Empty or missing sections

Check that:
- Doxygen XML was generated successfully (`ls docs/xml/`)
- XML files contain the expected tags (`@param`, `@return`, etc.)
- Documentation comments use `/**` (not `/*`)

### Quarto not found

Install Quarto:
```bash
brew install quarto  # macOS
```

Or download from https://quarto.org

### Book won't render

Check `_quarto.yml` syntax:
```bash
quarto check
```

## Resources

- [Quarto Documentation](https://quarto.org/docs/guide/)
- [Quarto Books](https://quarto.org/docs/books/)
- [Quarto Themes](https://quarto.org/docs/output-formats/html-themes.html)
- [Quarto Publishing](https://quarto.org/docs/publishing/)
