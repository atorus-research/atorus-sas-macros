# %xuepoch

## Overview
The `%xuepoch` macro derives the EPOCH variable for SDTM datasets using the Study Elements (SE) domain. It determines the study epoch for each record based on the timing of events relative to study milestones defined in SE, handling both complete and partial dates with appropriate comparison logic.

## Version Information
- Version: 1.0
- Last Updated: 20JUL2022
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Datasets:
  - SE domain in SDTM library
- Required Macros:
  - `%xuload`: Used to load the SE domain

## Parameters
- **inds** (required): Name of the input dataset to derive EPOCH for.
- **dtcdate** (required): Name of the date variable to use for epoch determination.
- **outds** (optional): Name of the output dataset. Default: value of `inds`.
- **debug** (optional): Flag determining whether to retain temporary datasets. Default: N.

## Return Values/Output
- Creates or updates a dataset containing all variables from the input dataset plus:
  - EPOCH: Character variable containing the derived study epoch
- When debug=N, temporary variables are dropped from the output
- Log messages for parameter validation and processing status

## Processing Details
1. Parameter validation:
   - Checks for required parameters
   - Verifies parameter values are not empty
2. Data processing:
   - Loads SE domain using `%xuload`
   - Sorts SE by USUBJID and SESTDTC
   - Transposes SE to create one record per subject with epoch start dates
3. Epoch derivation:
   - Merges input data with transposed SE data
   - Compares dates using sophisticated logic:
     - Full datetime comparison for complete datetime values
     - Date-only comparison when time is not available
     - Partial date comparison for incomplete dates
   - Assigns EPOCH based on the most recent epoch start date before the record's date

## Examples
```sas
/* Basic usage - derive EPOCH for LB domain using LBDTC */
%xuepoch(lb, lbdtc);

/* Specify custom output dataset */
%xuepoch(ae, aedtc, outds=ae_with_epoch);

/* Keep temporary datasets for debugging */
%xuepoch(vs, vsdtc, debug=Y);
```

## Common Issues and Solutions
1. **Missing SE Domain**
   - Issue: SE domain not found in SDTM library
   - Solution: Ensure SE domain is present and accessible

2. **Date Comparison Issues**
   - Issue: Unexpected EPOCH assignments
   - Solution: Verify date formats and completeness in both input and SE datasets

3. **Missing EPOCH Values**
   - Issue: Records with no assigned EPOCH
   - Solution: Check if dates fall within any defined study epochs in SE

## Notes and Limitations
1. The macro assumes the SE domain follows SDTM standards with required variables USUBJID, SESTDTC, and EPOCH.
2. Date comparisons handle three scenarios:
   - Complete datetime values (length=16)
   - Date-only values (length=10)
   - Partial dates (length<10)
3. When comparing dates of different completeness, the comparison uses the length of the less complete date.
4. The macro preserves all input dataset variables in the output.

## Related Macros
- `%xuload`: Used to load SDTM datasets
- `%xuvisit`: Derives VISIT/VISITNUM variables
- `%xcdtc2dt`: Converts ISO 8601 dates to SAS dates

## Change Log
### Version 1.0 (20JUL2022)
- Initial release
- Basic epoch derivation functionality
- Handling of complete and partial dates
- Debug mode implementation 