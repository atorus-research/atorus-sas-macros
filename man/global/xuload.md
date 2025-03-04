# %xuload - Dataset Loading and Format Management Utility

## Overview
The `%xuload` macro loads datasets into the SAS work library while managing formats and informats. It provides flexible control over format handling, dataset sorting, and encoding, with three distinct modes for format processing: smart, keep, and remove.

## Version Information
- **Version**: 1.0
- **Last Updated**: 13JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No macro dependencies
- Optional format catalog (.sas7bcat) for 'keep' mode

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Space-separated list of input dataset names |
| sourcelib | Yes | - | Name of the input library |
| sortvars | No | - | Variables to sort by |
| encoding | No | - | Dataset encoding specification |
| mode | No | smart | Format processing mode (smart/keep/remove) |
| fmtlib | No | &sourcelib | Library containing format catalogs (required for keep mode) |
| debug | No | N | Whether to retain temporary datasets (Y/N) |

## Return Values/Output
Creates in WORK library:
- Loaded datasets with processed formats/informats
- Optional sorting applied if specified
- Log messages for format processing actions

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Validates mode parameter values
   - Checks dataset existence
   - Validates format catalog availability for 'keep' mode

2. Format Processing Modes:
   - **smart**: Removes unexpected formats/informats
   - **keep**: Preserves formats using specified format catalog
   - **remove**: Strips all formats/informats

3. Dataset Processing:
   - Loads datasets with specified encoding
   - Applies format processing according to mode
   - Performs optional sorting
   - Handles multiple datasets sequentially

## Examples

### Basic Usage
```sas
%xuload(dm, sdtm, sortvars=usubjid);
```

### Multiple Datasets with Format Preservation
```sas
%xuload(dm ae, crf, encoding=asciiany, mode=keep, fmtlib=crf);
```

### Remove All Formats
```sas
%xuload(
    inds=adsl adae,
    sourcelib=adam,
    mode=remove,
    sortvars=usubjid
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing format catalog | Verify .sas7bcat exists in fmtlib |
| Dataset not found | Check sourcelib and dataset names |
| Invalid formats | Use 'smart' mode to clean formats |

## Notes and Limitations
- 'smart' mode removes formats not in SASHELP.VFORMAT
- 'keep' mode requires valid format catalog
- 'remove' mode strips ALL formats/informats
- Processes multiple datasets sequentially
- Temporary format search path modification in 'keep' mode
- Debug mode retains intermediate processing datasets

## Related Macros
- xufmt.sas - For format creation
- Other dataset management macros
- Data standardization utilities

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 13JUL2022 | Atorus Research | Initial version | 