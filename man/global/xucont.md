# %xucont - Dataset Contents Procedure Utility

## Overview
The `%xucont` macro executes the CONTENTS procedure on one or more datasets, providing detailed information about dataset attributes, variables, and metadata. It supports multiple datasets and customizable CONTENTS procedure options while handling error checking for dataset existence.

## Version Information
- **Version**: 1.0
- **Last Updated**: 12AUG2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No macro dependencies

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Space-separated list of input dataset names |
| sourcelib | Yes | - | Name of the input library |
| contopts | No | varnum | Options for the CONTENTS procedure |

## Return Values/Output
Generates CONTENTS procedure output for each dataset:
- Dataset attributes
- Variable information
- Index information
- Sort information
- Additional metadata based on specified options

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Checks for non-empty values
   - Validates dataset existence

2. Dataset Processing:
   - Parses multiple dataset names
   - Verifies each dataset exists
   - Handles errors individually

3. Output Generation:
   - Executes CONTENTS procedure
   - Applies specified options
   - Generates separate output for each dataset

## Examples

### Basic Usage
```sas
%xucont(dm, sdtm);
```

### Multiple Datasets
```sas
%xucont(dm suppdm ae suppae, sdtm);
```

### Custom Options
```sas
%xucont(
    inds=adsl adae,
    sourcelib=adam,
    contopts=varnum short
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Dataset not found | Verify dataset exists in library |
| Invalid library | Check library assignment |
| Invalid options | Review PROC CONTENTS documentation |

## Notes and Limitations
- Processes multiple datasets sequentially
- Continues processing after dataset errors
- Default option is VARNUM for variable ordering
- Reports errors for missing datasets
- Each dataset processed independently
- No temporary datasets created
- Output format follows PROC CONTENTS standards
- Error messages identify specific dataset issues

## See Also
- [`%xuload`](/man/global/xuload.md): Dataset loading utility
- [`%xusave`](/man/global/xusave.md): Dataset saving utility
- [`%xuct`](/man/global/xuct.md): Controlled terminology validation

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 12AUG2022 | Atorus Research | Initial version | 