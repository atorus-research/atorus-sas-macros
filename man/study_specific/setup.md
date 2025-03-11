# %setup - Study Environment Setup Utility

## Overview
The `%setup` macro initializes the study environment by setting up global variables for directory paths and creating library references. It processes directory structure information to establish paths for client, protocol, and task-specific locations, and creates standardized library references for study data.

## Version Information
- **Version**: 1.0
- **Last Updated**: 18FEB2021
- **Author(s)**: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Macros:
  - `%xuprogpath`: For determining program execution path and setting initial global variables
- No external files/datasets required

## Parameters
This macro has no parameters as it is designed to run automatically within the `%xumprint` macro.

## Return Values/Output
Creates the following:

### Global Variables
- `__clnt_I`: Client folder path component with separator
- `__subfolders_I`: Subfolder path components with separators
- `__side_I`: Side folder path component with separator

### Library References
Standard Libraries:
- `specs`: Specifications folder
- `crf`: CRF data
- `external`: External data
- `dict`: Dictionary/reference data
- `rawmisc`: Miscellaneous raw data
- `raw`: Concatenation of crf, external, dict, and rawmisc

Production/Validation Libraries (when `__side` is defined):
- Production:
  - `sdtm`: SDTM datasets
  - `adam`: ADaM datasets
  - `tfl`: Tables, Figures, and Listings
  - `misc`: Miscellaneous files
- Validation:
  - `vsdtm`: Validation SDTM datasets
  - `vadam`: Validation ADaM datasets
  - `vtfl`: Validation TFLs
  - `vmisc`: Validation miscellaneous files

## Processing Details
1. Initial Setup:
   - Calls `%xuprogpath` to determine program path and set initial variables
   - Creates conditional setup macro for directory structure processing

2. Directory Structure Processing:
   - Processes `__clnt` variable to create `__clnt_I`
   - Processes `__subfolders` variable to create `__subfolders_I`
   - Processes `__side` variable to create `__side_I`

3. Library Assignment:
   - Creates standard library references for raw data
   - Conditionally creates production/validation libraries based on `__side` value
   - Sets up SASAUTOS path for macro libraries

## Examples

### Automatic Usage
```sas
/* The macro is called automatically by %xumprint */
%xumprint(route=YES);
```

### Manual Usage (if needed)
```sas
/* First call xuprogpath to set required globals */
%xuprogpath;

/* Then run setup */
%setup;
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing library paths | Verify directory structure matches expected pattern |
| Invalid permissions | Check user access to specified directories |
| Missing global variables | Ensure `%xuprogpath` is called before `%setup` |

## Notes and Limitations
1. Directory Structure:
   - Assumes standard project directory structure
   - Requires specific folder hierarchy for proper path resolution
   - Handles both production/validation separated and combined structures

2. Library References:
   - Creates standard set of library references
   - Adapts to presence/absence of validation directories
   - All paths use OS-appropriate separators

3. Usage Context:
   - Designed for automatic execution within `%xumprint`
   - Can be run standalone if needed
   - Requires prior execution of `%xuprogpath`

## See Also
- [`%xuprogpath`](/man/global/xuprogpath.md): Program path resolution utility
- [`%xumprint`](/man/global/xumprint.md): Program execution wrapper

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 18FEB2021 | Rostyslav Didenko | Initial version | 