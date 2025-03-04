# %kutitles

## Overview
The `%kutitles` macro assigns titles to SAS outputs based on specifications from a TFL (Tables, Figures, and Listings) titles file. It manages global and program-specific titles, handles title justification, and automatically includes page numbers and timestamps in standard locations.

## Version Information
- Version: 1.0
- Last Updated: 17SEP2022
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Files:
  - `TFL_titles.csv` in specified filepath
- Required Global Variables:
  - `__root`: Root directory path (created automatically by xuprogpath.sas)
  - `__clnt_I`: Client identifier (created automatically by xuprogpath.sas)
  - `__comp`: Compound identifier (created automatically by xuprogpath.sas)
  - `__prot`: Protocol identifier (created automatically by xuprogpath.sas)
  - `__subfolders_I`: Subfolder structure (created automatically by xuprogpath.sas)
  - `__task`: Task identifier (created automatically by xuprogpath.sas)
  - `tmstmp_date`: Current date (created automatically by jdtflstyle.sas)
  - `tmstmp_time`: Current time (created automatically by jdtflstyle.sas)

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| progname | Yes | - | Program name to search in TFL_titles.csv |
| filepath | No | `&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs` | Path to TFL_titles.csv |
| seq | No | 1 | Sequence number of output in TFL_titles.csv |
| justify | No | c | Title alignment (l/c/r) |
| escapechar | No | $ | ODS escape character |
| debug | No | N | Flag to retain temporary datasets |

## Return Values/Output
- Sets up to 5 title lines:
  - Title1: Left-justified title with right-justified page number
  - Title2: Left-justified title with right-justified program name and timestamp
  - Title3-5: Justified according to parameter setting
- Log messages indicating:
  - Missing parameters
  - Missing titles file
  - Multiple title entries
  - Missing global titles

## Processing Details
1. Parameter validation:
   - Checks required parameters
   - Verifies TFL_titles.csv existence
   - Validates parameter values

2. Title preparation:
   - Clears existing titles
   - Imports titles file
   - Checks for duplicate entries
   - Processes global titles

3. Title formatting:
   - Handles quotation marks
   - Applies justification
   - Adds page numbers
   - Includes timestamps

4. Title assignment:
   - Sets up to 5 title lines
   - Applies specified formatting
   - Manages missing titles
   - Cleans up temporary data

## Examples
```sas
/* Basic usage for single output */
%kutitles(s_000_ae3, seq=1);

/* Custom justification and filepath */
%kutitles(l_000_dm,
          filepath=/path/to/specs,
          justify=l);

/* Debug mode with custom escape character */
%kutitles(t_14_3_1_1,
          seq=2,
          escapechar=~,
          debug=Y);
```

## Common Issues and Solutions
1. **Missing Titles File**
   - Error: "TFL_titles.csv was not found"
   - Solution: Verify file path and existence

2. **Multiple Title Entries**
   - Warning: "multiple rows present for [program]"
   - Solution: Review and correct TFL_titles.csv

3. **Missing Global Titles**
   - Warning: "title1 and title2 were not resolved"
   - Solution: Check GlobalTitle1/2 in TFL_titles.csv

## Notes and Limitations
1. Title structure:
   - Maximum 5 title lines
   - Standard header format
   - Automatic page numbering
   - Program identification

2. File requirements:
   - CSV format
   - Specific column structure
   - Global title definitions
   - Program-specific entries

3. Processing behavior:
   - Clears existing titles
   - Handles missing entries
   - Preserves title order
   - Manages special characters

## Related Macros
- `%jdtflstyle`: Output styling
- `%kplotrtf`: RTF plot generation
- Other TFL formatting macros

## Change Log
### Version 1.0 (17SEP2022)
- Initial release
- Basic title management
- Global title support
- Automatic page numbering 