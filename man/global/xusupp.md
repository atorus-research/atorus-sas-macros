# %xusupp - SDTM Supplemental Qualifier Domain Creation Utility

## Overview
The `%xusupp` macro creates and manages SDTM supplemental qualifier (SUPP--) domains by adding variables that don't fit into the parent domain's standard structure. It handles the creation and appending of supplemental records while maintaining SDTM standards and managing variable relationships between parent and supplemental domains.

## Version Information
- **Version**: 1.0
- **Last Updated**: 18JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Required global variable:
  - domain: Parent domain identifier (e.g., 'DM' for Demographics)
- Required datasets:
  - EMPTY_SUPP[domain]: Empty supplemental qualifier template
  - Parent domain dataset

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Name of the input dataset |
| invar | Yes | - | Name of the variable to add to SUPP-- domain |
| idvar | No | [domain]seq* | Name of the identifier variable (*except for DM domain) |
| qlabel | No | Variable label | Text to display in QLABEL variable |
| qorig | No | - | Text to display in QORIG variable |
| qeval | No | - | Text to display in QEVAL variable |
| debug | No | N | Whether to retain temporary datasets (Y/N) |

## Return Values/Output
Creates or updates SUPP[domain] dataset containing:
- Standard SDTM supplemental qualifier structure
- Required variables:
  - STUDYID, RDOMAIN, USUBJID
  - IDVAR/IDVARVAL (when applicable)
  - QNAM, QLABEL, QVAL
  - QORIG, QEVAL
- Sorted and de-duplicated records

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Validates domain variable existence
   - Handles special DM domain case
   - Determines appropriate identifier variable

2. Data Processing:
   - Sorts input data by key variables
   - Transposes supplemental data
   - Determines variable types
   - Handles labels appropriately

3. Output Generation:
   - Creates SUPP-- records
   - Appends to existing SUPP-- domain
   - Removes duplicates
   - Maintains SDTM standards

## Examples

### Basic Usage for Demographics
```sas
%let domain = DM;
%xusupp(
    inds=dm,
    invar=RACEOTH,
    qlabel=%str(Race, Other),
    qorig=CRF
);
```

### Custom Identifier Variable
```sas
%let domain = AE;
%xusupp(
    inds=ae,
    invar=AEACNOTH,
    idvar=AESEQ,
    qlabel=Other Action Taken
);
```

### Debug Mode
```sas
%let domain = VS;
%xusupp(
    inds=vs,
    invar=VSPOS,
    qorig=CRF,
    qeval=INVESTIGATOR,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing domain variable | Set global domain variable before call |
| Duplicate records | Check input data uniqueness |
| Missing labels | Specify qlabel or add variable labels |

## Notes and Limitations
- Requires pre-existing empty SUPP domain template
- DM domain ignores idvar parameter
- Non-DM domains use [domain]seq by default
- Automatically handles numeric/character IDs
- Appends to existing SUPP-- datasets
- De-duplicates final dataset
- Variable labels used for QLABEL if not specified
- Debug mode retains intermediate datasets

## Related Macros
- SDTM domain creation macros
- Data standardization utilities
- Variable management tools

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 18JUL2022 | Atorus Research | Initial version | 