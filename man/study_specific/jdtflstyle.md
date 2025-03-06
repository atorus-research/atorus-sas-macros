# %jdtflstyle

## Overview
The `%jdtflstyle` macro creates a style template for study PDF/RTF outputs. It opens ODS PDF/RTF destination, creates output files with specified formatting, and generates global macro variables containing timestamps. The macro implements custom styles based on SAS ODS style templates, markup, and tagsets.

## Version Information
- Version: 1.0
- Last Updated: 05MAY2021
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Global Variables:
  - `__root`: Root directory path (created automatically by xuprogpath.sas)
  - `__clnt_I`: Client identifier (created automatically by xuprogpath.sas)
  - `__comp`: Compound identifier (created automatically by xuprogpath.sas)
  - `__prot`: Protocol identifier (created automatically by xuprogpath.sas)
  - `__subfolders_I`: Subfolder structure (created automatically by xuprogpath.sas)
  - `__task`: Task identifier (created automatically by xuprogpath.sas)
  - `__level`: Development level (created automatically by xuprogpath.sas)
  - `__side_I`: Production side (created automatically by xuprogpath.sas)
- No macro dependencies

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| filename | Yes | - | Name of the output file |
| filepath | No | `&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&__side_I.&II.tfl` | File save path |
| type | No | RTF | File extension (RTF/PDF) |
| lmarg | No | 1in | Left margin size |
| rmarg | No | 1in | Right margin size |
| tmarg | No | 0.5in | Top margin size |
| bmarg | No | 1in | Bottom margin size |
| escapechar | No | $ | Escape character for ODS |

## Return Values/Output
- Creates output file:
  - `[filename].rtf` or `[filename].pdf` in specified filepath
- Creates global macro variables:
  - `timestamp`: Current datetime in E8601DT16. format
  - `tmstmp_date`: Date portion of timestamp
  - `tmstmp_time`: Time portion of timestamp
- Applies custom style template (glst1) with:
  - Courier font family
  - 9pt font size
  - Specific table, header, and title formatting

## Processing Details
1. Parameter validation:
   - Checks for empty required parameters
   - Validates file type (RTF/PDF)
   - Verifies path components

2. Style template creation:
   - Defines custom style (glst1)
   - Sets font properties
   - Configures table formatting
   - Establishes header/footer styles

3. Output generation:
   - Creates timestamp variables
   - Sets page orientation and margins
   - Opens appropriate ODS destination
   - Applies style template

## Examples
```sas
/* Basic usage - create RTF output */
%jdtflstyle(T_10_1_1);

/* Create PDF with custom bottom margin */
%jdtflstyle(F_15_1_2, 
           type=PDF,
           bmarg=0.8in);

/* Specify custom filepath and escape character */
%jdtflstyle(T_14_2_1,
           filepath=/path/to/output,
           escapechar=~);
```

## Common Issues and Solutions
1. **Invalid File Type**
   - Error: "parameter type should be RTF or PDF"
   - Solution: Specify either RTF or PDF (case-insensitive)

2. **Missing Parameters**
   - Error: "[parameter] is required parameter and should not be NULL"
   - Solution: Provide all required parameters

3. **Path Issues**
   - Issue: File not created in expected location
   - Solution: Verify global variables for path construction

## Notes and Limitations
1. Style template specifications:
   - Fixed font family (Courier)
   - Fixed font size (9pt)
   - Predefined table formatting
   - Standard header/footer styling

2. Output settings:
   - Landscape orientation
   - ACTXIMG device
   - No automatic date/number
   - No automatic titles/footnotes

3. Global variable dependencies:
   - Requires specific project structure
   - Uses standard directory separators
   - Assumes specific naming conventions

## See Also
- [`%kutitles`](/man/study_specific/kutitles.md): Title and footnote management
- Other TFL formatting macros

## Change Log
### Version 1.0 (05MAY2021)
- Initial release
- Basic style template functionality
- RTF/PDF output support
- Timestamp variable creation 