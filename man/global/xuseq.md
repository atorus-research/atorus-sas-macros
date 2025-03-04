# %xuseq - Sequence Number Generation Utility

## Overview
The `%xuseq` macro creates sequence numbers for observations within a dataset, typically used in clinical data standards to generate --SEQ variables. It assigns sequential numbers based on specified sorting criteria, with options for customizing the sequence variable name prefix.

## Version Information
- **Version**: 1.0
- **Last Updated**: 14JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Optional global variable:
  - domain: Default prefix for sequence variable if prefix parameter not specified

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Name of the input dataset |
| sortvars | Yes | - | Space-separated list of variables to sort by |
| prefix | No | &domain | Prefix for the sequence variable name |
| debug | No | N | Whether to retain temporary variables (Y/N) |

## Return Values/Output
Modifies input dataset to include:
- New sequence variable named [prefix]SEQ
- Sequential numbers starting at 1 for each unique combination of sort variables
- Original dataset structure preserved
- Temporary variables removed unless debug=Y

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Checks prefix resolution:
     - Uses specified prefix if provided
     - Uses &domain value if available and prefix not specified
     - Errors if neither available

2. Data Processing:
   - Sorts dataset by specified variables
   - Creates temporary counter variable
   - Generates sequence numbers
   - Assigns values to final sequence variable

3. Cleanup:
   - Removes temporary variables unless in debug mode
   - Maintains original dataset structure

## Examples

### Basic Usage with Domain Variable
```sas
%let domain = AE;
%xuseq(ae, usubjid);
```

### Custom Prefix
```sas
%xuseq(
    inds=adlb,
    sortvars=usubjid paramcd adt,
    prefix=a
);
```

### Debug Mode
```sas
%xuseq(
    inds=vs,
    sortvars=usubjid visitnum,
    prefix=vs,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing prefix | Set domain variable or specify prefix parameter |
| Sort variable not found | Verify all sort variables exist in dataset |
| Duplicate sequences | Review sort criteria for uniqueness |

## Notes and Limitations
- Sequence numbers restart at 1 for each unique USUBJID
- Sort order must include USUBJID
- Prefix must follow naming conventions
- Debug mode retains __tmp_n variable
- Modifies input dataset in place
- Sort variables determine sequence grouping
- Assumes USUBJID is present in dataset

## Related Macros
- SDTM/ADaM sequence generation macros
- Dataset sorting utilities
- Variable creation tools

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 14JUL2022 | Atorus Research | Initial version | 