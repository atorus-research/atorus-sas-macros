# %xuvisit - SDTM Visit and Visit Number Derivation Utility

## Overview
The `%xuvisit` macro derives VISIT and VISITNUM variables for SDTM datasets using Trial Visits (TV) and Subject Visits (SV) domains as references. It handles both scheduled and unscheduled visits, ensuring proper visit numbering and naming according to SDTM standards.

## Version Information
- **Version**: 1.0
- **Last Updated**: 19JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Required macros:
  - xuload.sas - For loading reference domains
- Required datasets:
  - TV domain in SDTM library
  - SV domain in SDTM library

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Name of the input dataset |
| dtcdate | Yes | - | Name of the date variable for visit timing |
| outds | No | &inds | Name of the output dataset |
| debug | No | N | Whether to retain temporary datasets (Y/N) |

## Return Values/Output
Creates a dataset containing:
- All variables from input dataset
- Derived VISIT variable:
  - From TV for scheduled visits
  - From SV for unscheduled visits
- Derived VISITNUM variable:
  - Numeric visit identifier
  - Matches TV/SV reference data
  - Properly sequenced for unscheduled visits

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Checks for non-empty values

2. Reference Data Processing:
   - Loads TV and SV domains
   - De-duplicates visit information
   - Prepares unscheduled visit data

3. Visit Assignment:
   - Merges scheduled visits from TV
   - Identifies unscheduled visits
   - Assigns visit numbers and names
   - Handles date-based visit timing

## Examples

### Basic Usage
```sas
%xuvisit(vs, vsdtc);
```

### Custom Output Dataset
```sas
%xuvisit(
    inds=ae,
    dtcdate=aestdtc,
    outds=ae_visit
);
```

### Debug Mode
```sas
%xuvisit(
    inds=lb,
    dtcdate=lbdtc,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing TV/SV data | Ensure reference domains are in SDTM library |
| Unmatched visits | Check visit naming consistency |
| Date misalignment | Verify date variable format |

## Notes and Limitations
- Requires TV and SV domains in SDTM library
- Unscheduled visits identified by "UNS" (case-insensitive)
- Uses date substring (first 10 characters) for timing
- Preserves original dataset structure
- Debug mode retains intermediate datasets
- Assumes consistent visit naming across domains
- Handles both scheduled and unscheduled visits
- Maintains SDTM compliance

## Related Macros
- SDTM timing variables macros
- Visit and date handling utilities
- Data standardization tools

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 19JUL2022 | Atorus Research | Initial version | 