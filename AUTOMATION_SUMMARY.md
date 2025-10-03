# Documentation Automation Summary

## Complete Workflow: SAS Macros → Doxygen XML → Quarto Book

This repository now has a complete automated documentation pipeline that converts SAS macro headers into beautiful, searchable Quarto books.

## Quick Start

### Generate Complete Documentation

```bash
# 1. Generate Doxygen XML from SAS files
doxygen Doxyfile

# 2. Convert XML to Quarto markdown files
python3 xml_to_qmd.py --create-book-config

# 3. Build the Quarto book
cd quarto && quarto render
```

### Preview the Book

```bash
cd quarto
quarto preview
```

Opens a live-preview in your browser at http://localhost:4200

## What Was Created

### 1. Doxygen Configuration
- **[Doxyfile](Doxyfile)** - Simplified R-style documentation config
- **[DOXYGEN_README.md](DOXYGEN_README.md)** - Doxygen usage guide
- **[DOXYGEN_TEMPLATE.sas](DOXYGEN_TEMPLATE.sas)** - Template for new macros

### 2. Python Conversion Script
- **[xml_to_qmd.py](xml_to_qmd.py)** - Automated XML → Quarto converter
- **[QUARTO_README.md](QUARTO_README.md)** - Quarto book guide

### 3. Generated Files
After running the scripts:
```
docs/
├── html/          # Doxygen HTML output
└── xml/           # Doxygen XML (source for Quarto)

quarto/
├── _quarto.yml    # Book configuration
├── index.qmd      # Book homepage
├── macros/        # Individual macro docs
│   ├── xcdtc2dt.qmd
│   ├── xuepoch.qmd
│   └── ...        # 31 total .qmd files
└── _book/         # Rendered book (after quarto render)
```

## File Organization

### SAS Source Files
```
sas/
├── global/           # 23 global utility macros
│   ├── xcdtc2dt.sas
│   ├── xuepoch.sas
│   └── ...
└── study_specific/   # 8 study-specific macros
    ├── kdident.sas
    └── ...
```

All have Doxygen-formatted headers.

### Documentation Outputs

**Two Formats Available:**

1. **Doxygen HTML** (in `docs/html/`)
   - Auto-generated from XML
   - Technical reference style
   - Includes search functionality

2. **Quarto Book** (in `quarto/_book/`)
   - Beautiful, modern design
   - Better for reading/learning
   - Customizable themes
   - Can export to PDF, Word, etc.

## Documentation Format

### SAS Macro Headers

All 31 macros use this standardized format:

```sas
/**
* @file macroname.sas
* @brief One-line description
* @details Longer explanation (optional)
*
* @param[in] param1 Description (Required)
* @param[in] param2 Description (Default: value)
*
* @return What the macro produces
*
* @par Example:
* @code
* %macroname(param1=value);
* @endcode
*
* @author Atorus Research
* @date DD-MMM-YYYY
*/
```

### Generated Quarto Format

Each `.qmd` file contains:

```markdown
---
title: "macroname"
author: "Atorus Research"
date: "DD-MMM-YYYY"
---

## Description
...

## Parameters
**`param1`**
: Description
  *Required:* Yes

## Returns
...

## Examples
```sas
%macroname(param1=value);
```
```

## Workflow Diagram

```
┌─────────────────┐
│  SAS Macros     │  31 files with /** */ doc blocks
│  (sas/*.sas)    │
└────────┬────────┘
         │
         ▼
    [doxygen]
         │
         ▼
┌─────────────────┐
│  Doxygen XML    │  31 XML files
│  (docs/xml/)    │
└────────┬────────┘
         │
         ▼
  [xml_to_qmd.py]
         │
         ▼
┌─────────────────┐
│  Quarto Files   │  31 .qmd files + config
│  (quarto/*.qmd) │
└────────┬────────┘
         │
         ▼
  [quarto render]
         │
         ▼
┌─────────────────┐
│  HTML Book      │  Beautiful documentation
│  (_book/)       │
└─────────────────┘
```

## Python Script Features

### xml_to_qmd.py Capabilities

✅ **Parses** Doxygen XML files
✅ **Extracts** all documentation elements:
  - Brief/detailed descriptions
  - Parameters with Required/Default info
  - Return values
  - Code examples
  - Author & date metadata
  - Remarks/notes

✅ **Generates** Quarto markdown files
✅ **Creates** book configuration automatically
✅ **Organizes** macros into Global/Study-Specific sections

### Command Line Options

```bash
# Basic - just convert XML to QMD
python3 xml_to_qmd.py

# With book config files
python3 xml_to_qmd.py --create-book-config

# Custom directories
python3 xml_to_qmd.py \
  --xml-dir docs/xml \
  --output-dir quarto/macros \
  --create-book-config

# Help
python3 xml_to_qmd.py --help
```

## Customizing the Quarto Book

### Change Theme

Edit `quarto/_quarto.yml`:

```yaml
format:
  html:
    theme: flatly  # Options: cosmo, flatly, darkly, journal, etc.
```

### Add Logo

```yaml
format:
  html:
    theme: cosmo
    logo: logo.png
```

### Export to PDF

```yaml
format:
  html:
    theme: cosmo
  pdf:
    documentclass: scrbook
```

Then: `quarto render --to pdf`

### Export to Word

```yaml
format:
  html:
    theme: cosmo
  docx:
    toc: true
```

Then: `quarto render --to docx`

## Automated Regeneration

### Quick Update Script

Create `update_docs.sh`:

```bash
#!/bin/bash
echo "Updating documentation..."

# Generate XML
doxygen Doxyfile

# Convert to Quarto
python3 xml_to_qmd.py --create-book-config

# Build book
cd quarto && quarto render

echo "✓ Documentation updated in quarto/_book/"
```

Usage:
```bash
chmod +x update_docs.sh
./update_docs.sh
```

### CI/CD Integration

See [QUARTO_README.md](QUARTO_README.md) for GitHub Actions example.

## Publishing Options

### 1. GitHub Pages

```bash
# Render book
cd quarto && quarto render

# Commit and push _book/ directory
git add quarto/_book
git commit -m "Update documentation"
git push

# Configure GitHub Pages → Settings → Pages → Source: /quarto/_book
```

### 2. Quarto Pub

```bash
cd quarto
quarto publish quarto-pub
```

### 3. Self-Hosted

Copy `quarto/_book/` to your web server.

## Maintenance

### Adding a New Macro

1. **Create SAS file** with doxygen header:
   ```sas
   /**
   * @file newmacro.sas
   * @brief Description
   * ...
   */
   %macro newmacro(...);
   ```

2. **Regenerate documentation**:
   ```bash
   doxygen Doxyfile
   python3 xml_to_qmd.py --create-book-config
   cd quarto && quarto render
   ```

### Updating Existing Documentation

1. **Edit SAS file** header
2. **Regenerate**: Run the same commands above

The script automatically overwrites old .qmd files.

## File Checklist

✅ Configuration Files:
- [ ] Doxyfile
- [ ] xml_to_qmd.py
- [ ] quarto/_quarto.yml
- [ ] quarto/index.qmd

✅ Documentation:
- [ ] DOXYGEN_README.md
- [ ] QUARTO_README.md
- [ ] DOXYGEN_TEMPLATE.sas

✅ Generated (gitignored):
- [ ] docs/xml/
- [ ] docs/html/
- [ ] quarto/_book/
- [ ] quarto/macros/*.qmd

## Prerequisites

### Required Software

1. **Doxygen**
   ```bash
   brew install doxygen
   ```

2. **Python 3.6+**
   ```bash
   python3 --version
   ```

3. **Quarto**
   ```bash
   brew install quarto
   # Or download from https://quarto.org
   ```

### Check Installation

```bash
doxygen --version    # Should show version
python3 --version    # Should show 3.6+
quarto --version     # Should show version
```

## Benefits

### For Documentation Writers
✅ Write docs once (in SAS headers)
✅ Auto-generate multiple formats
✅ Standardized format across all macros
✅ Easy to maintain

### For Users
✅ Beautiful, searchable documentation
✅ Consistent structure
✅ Code examples included
✅ Multiple export formats (HTML, PDF, Word)

### For Teams
✅ Automated workflow
✅ Version controlled
✅ CI/CD ready
✅ Easy to publish

## Support Files

- **[DOXYGEN_README.md](DOXYGEN_README.md)** - Complete Doxygen guide
- **[QUARTO_README.md](QUARTO_README.md)** - Complete Quarto guide
- **[DOXYGEN_SUMMARY.md](DOXYGEN_SUMMARY.md)** - Doxygen setup overview
- **[DOXYGEN_TEMPLATE.sas](DOXYGEN_TEMPLATE.sas)** - Template for new macros

## Next Steps

1. **Review generated Quarto book**:
   ```bash
   cd quarto
   quarto preview
   ```

2. **Customize** `_quarto.yml` to your preferences

3. **Publish** to GitHub Pages or Quarto Pub

4. **Set up CI/CD** for automatic updates (see QUARTO_README.md)

5. **Share** the documentation URL with your team!
