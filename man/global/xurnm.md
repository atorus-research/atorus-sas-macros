# %xurnm - Variable Renaming Utility

## Overview
The `%xurnm` macro provides functionality to rename all variables in a dataset by either adding a prefix or removing characters from the beginning of variable names. It handles special characters in variable names and maintains the dataset structure while performing bulk renaming operations.

## Version Information
- **Version**: 1.0
- **Last Updated**: 14JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No macro dependencies

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Name of the input dataset |
| mode | Yes | add | Working mode: 'add' to add prefix, 'remove' to remove characters |
| prefix | No* | _ | Characters to add before variable names (*Required if mode=add) |
| rchar | No* | 1 | Number of characters to remove from start of variable names (*Required if mode=remove) |
| outds | No | &inds | Name of output dataset |
| debug | No | N | Whether to retain temporary datasets (Y/N) |

## Return Values/Output
Creates a dataset containing:
- All variables from input dataset
- Renamed variables according to specified mode:
  - add: All variables prefixed with specified characters
  - remove: Specified number of characters removed from start of names

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Validates mode parameter (add/remove)
   - Checks conditional requirements:
     - prefix required for add mode
     - rchar required for remove mode

2. Variable Processing:
   - Extracts dataset metadata using PROC CONTENTS
   - Maintains variable order using VARNUM
   - Creates rename list handling special characters

3. Renaming Operation:
   - Handles special characters using VALIDVARNAME syntax
   - Processes all variables maintaining dataset structure
   - Creates new dataset with renamed variables

## Examples

### Add Prefix to Variables
```sas
%xurnm(ds, mode=add, prefix=PRE_);
```

### Remove Characters from Variable Names
```sas
%xurnm(
    inds=input_ds,
    mode=remove,
    rchar=2,
    outds=output_ds
);
```

### Debug Mode with Custom Output
```sas
%xurnm(
    inds=source,
    mode=add,
    prefix=TMP_,
    outds=renamed,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Invalid variable names | Use valid SAS naming conventions for prefix |
| Special characters | Macro handles special chars using VALIDVARNAME |
| Name length exceeded | Ensure final names are ≤32 characters |

## Notes and Limitations
- Maximum SAS variable name length is 32 characters
- Handles variables with special characters
- Preserves variable order from input dataset
- Debug mode retains temporary datasets for troubleshooting
- Mode parameter is case-insensitive
- Cannot selectively rename variables (applies to all)
- Original dataset structure is preserved

## See Also
- [`%xuload`](/man/global/xuload.md): Dataset loading utility
- [`%xusave`](/man/global/xusave.md): Dataset saving utility
- [`%xucont`](/man/global/xucont.md): Dataset contents utility

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 14JUL2022 | Atorus Research | Initial version | 