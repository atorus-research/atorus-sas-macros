# Doxygen Documentation for SAS Macros

This repository uses Doxygen to generate R-style documentation for SAS macros, focusing on:
- **Description** - What the macro does
- **Parameters** - Input arguments and their defaults
- **Examples** - Usage examples
- **Metadata** - Author and modification dates

## Quick Start

### 1. Install Doxygen

**macOS:**
```bash
brew install doxygen
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install doxygen
```

**Linux (RHEL/CentOS):**
```bash
sudo yum install doxygen
```

**Windows:**
Download from https://www.doxygen.nl/download.html

### 2. Generate Documentation

From the repository root:
```bash
doxygen Doxyfile
```

This creates:
- `docs/xml/` - XML documentation files
- `docs/html/` - HTML browsable documentation

### 3. View Documentation

**HTML:**
```bash
open docs/html/index.html  # macOS
xdg-open docs/html/index.html  # Linux
```

**XML:** Files are in `docs/xml/` directory

## Documentation Structure

### R-Style Format

Each SAS macro follows this simplified documentation format:

```sas
/**
* @file macroname.sas
* @brief Short description
*
* @details
* Longer description with implementation details.
*
* @param[in] param1 Description (Required)
* @param[in] param2 Description (Default: value)
* @param[in] param3 Description (Optional)
*
* @return What the macro produces
*
* @examples
* @code
* %macroname(param1=value);
* @endcode
*
* @author Author Name
* @date DD-MMM-YYYY
*/
```

### Key Sections

1. **@file** - Filename
2. **@brief** - One-line summary
3. **@details** - Detailed description (optional)
4. **@param[in]** - Parameters with Required/Default/Optional notation
5. **@return** - Output description
6. **@examples** - Usage examples in @code blocks
7. **@author** - Author name
8. **@date** - Date of creation/modification

## Generated Documentation

### HTML Documentation

The HTML output provides:
- Alphabetical index of all macros
- Individual pages for each macro with:
  - Description
  - Parameter list with defaults
  - Return values
  - Usage examples
  - Metadata (author, date)
- Search functionality
- Clean, readable format

### XML Documentation

XML files suitable for:
- Programmatic parsing
- Integration with documentation systems
- Custom XSLT transformations
- Automated workflows

Key XML files:
- `index.xml` - Main index
- `[filename]_8sas.xml` - Individual macro documentation
- `combine.xslt` - XSLT stylesheet for combining files

## Configuration

The `Doxyfile` is configured for simplicity:

**Enabled:**
- HTML output (clean, searchable)
- XML output (structured data)
- Parameter documentation
- Example code blocks
- Author and date metadata

**Disabled:**
- Source code browsing
- Graphs and diagrams
- Cross-reference links
- Todo/bug/test lists
- Detailed file information

This creates documentation similar to R's `?function` help pages.

## Customization

### Change Output Directory

Edit `Doxyfile`:
```
OUTPUT_DIRECTORY = /path/to/docs
```

### Add Project Logo

```
PROJECT_LOGO = path/to/logo.png
```

### Generate Only XML

```
GENERATE_HTML = NO
GENERATE_XML = YES
```

## Troubleshooting

### No documentation generated

Check:
1. Doxygen is installed: `which doxygen`
2. Documentation blocks use `/**` (not `/*`)
3. INPUT paths are correct in Doxyfile

### Missing parameters in output

Ensure:
- All `@param` tags match actual macro parameters
- Parameter descriptions are not empty
- Format is: `@param[in] name Description (Required/Optional/Default: value)`

### Styling issues

The configuration prioritizes simplicity over features. For advanced customization:
- Add custom CSS: `HTML_EXTRA_STYLESHEET`
- Modify layout: `LAYOUT_FILE`

## Example Workflow

1. **Document a new macro:**
   ```sas
   /**
   * @file mynewmacro.sas
   * @brief Calculate summary statistics
   *
   * @param[in] inds Input dataset (Required)
   * @param[in] var Variable to analyze (Required)
   * @param[in] outds Output dataset (Default: summary)
   *
   * @examples
   * @code
   * %mynewmacro(inds=mydata, var=age);
   * @endcode
   *
   * @author Your Name
   * @date 03-OCT-2025
   */
   ```

2. **Generate documentation:**
   ```bash
   doxygen Doxyfile
   ```

3. **Review:**
   ```bash
   open docs/html/index.html
   ```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Generate Documentation
on: [push]
jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Doxygen
        run: sudo apt-get install doxygen
      - name: Generate Docs
        run: doxygen Doxyfile
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/html
```

## Resources

- [Doxygen Manual](https://www.doxygen.nl/manual/)
- [Doxygen Tags Reference](https://www.doxygen.nl/manual/commands.html)
- Template: See `DOXYGEN_TEMPLATE.sas` in this repository
