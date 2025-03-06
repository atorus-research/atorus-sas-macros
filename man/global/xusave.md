# %xusave - Dataset Save and Export Utility

## Overview
The `%xusave` macro provides functionality to save datasets in both SAS (.sas7bdat) and transport (.xpt) formats while applying dataset modifications such as variable selection, sorting, and labeling. It's particularly useful for finalizing datasets in clinical research environments where standardized outputs are required.

## Version Information
- **Version**: 1.0
- **Last Updated**: 13JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No macro dependencies
- Write access to output library location

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Name of the input dataset |
| outlib | Yes | - | Name of the output library |
| outds | No | &inds | Name of the output dataset |
| keepvars | No | - | Space-separated list of variables to keep |
| sortvars | No | - | Space-separated list of variables to sort by |
| dslbl | No | - | Label for the dataset |
| xpt | No | Y | Whether to save transport file (Y/N) |
| debug | No | N | Whether to retain temporary datasets (Y/N) |

## Return Values/Output
Creates the following files:
- SAS dataset (.sas7bdat) in specified output library
- Transport file (.xpt) in same location if xpt=Y
- Both outputs include:
  - Selected variables (if keepvars specified)
  - Applied sorting (if sortvars specified)
  - Dataset label (if dslbl specified)

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Checks for non-empty values

2. Dataset Processing:
   - Creates intermediate working copy
   - Applies sorting if specified
   - Selects variables if specified
   - Applies dataset label if specified

3. File Creation:
   - Saves SAS dataset (.sas7bdat)
   - Creates transport file (.xpt) if requested
   - Cleans up temporary datasets unless in debug mode

## Examples

### Basic Usage
```sas
%xusave(dm, sdtm, outds=dm);
```

### Full Feature Usage
```sas
%xusave(
    inds=ae,
    outlib=sdtm,
    outds=ae,
    keepvars=studyid usubjid aeterm aestdtc,
    sortvars=usubjid aestdtc,
    dslbl=Adverse Events,
    xpt=Y
);
```

### Debug Mode
```sas
%xusave(
    inds=vs,
    outlib=sdtm,
    keepvars=studyid usubjid visit vsorres,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Write permission errors | Verify access to output location |
| Invalid variable names | Check keepvars list against dataset |
| Sort order issues | Ensure sortvars exist in final dataset |

## Notes and Limitations
- Transport files are automatically lowercase
- Temporary datasets use macro name prefix
- Debug mode retains intermediate datasets
- Sort variables must exist in kept variables
- Transport files follow SAS V5 format
- Output library must be pre-assigned
- Transport files created in same directory as SAS datasets

## See Also
- [`%xuload`](/man/global/xuload.md): Dataset loading utility
- [`%xuloadcsv`](/man/global/xuloadcsv.md): CSV file loading utility
- [`%xusplit`](/man/global/xusplit.md): Dataset splitting utility

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 13JUL2022 | Atorus Research | Initial version | 