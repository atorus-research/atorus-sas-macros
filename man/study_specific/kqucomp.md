# %kqucomp

## Overview
The `%kqucomp` macro performs dataset comparisons between production and QC versions of clinical trial datasets. It supports comparison of main datasets along with their associated supplemental qualifiers (SUPP--) and comments datasets, making it particularly useful for SDTM and ADaM dataset validation.

## Version Information
- Version: 1.0
- Last Updated: 20AUG2021
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Global Variables:
  - `domain`: Current domain being processed
  - `[domain]sortstring`: Sort variables for the domain (created automatically by xtorder.sas)
- No macro dependencies

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| base | No | `&domain` | Base dataset name for comparison |
| qc | No | qc | Prefix for QC dataset name |
| id | No | `&&&domain.sortstring` | List of ID variables for comparison |
| prod_lib | No | sdtm | Production library name |
| qc_lib | No | work | QC library name |
| crit | No | - | PROC COMPARE criterion specification |
| supp | No | N | Flag to compare supplemental qualifier datasets |
| com | No | N | Flag to compare comments datasets |

## Return Values/Output
- Generates PROC CONTENTS output for:
  - Base dataset
  - SUPP-- dataset (if supp=Y)
  - Comments dataset (if com=Y)
- Produces PROC COMPARE results showing:
  - Variable differences
  - Value differences
  - Attribute differences
  - Observation differences
- Log messages indicating:
  - Missing parameters
  - Dataset existence
  - Comparison results

## Processing Details
1. Parameter validation:
   - Checks required parameters
   - Verifies parameter values
   - Validates dataset existence

2. Main dataset comparison:
   - Executes PROC CONTENTS
   - Performs PROC COMPARE
   - Uses specified ID variables
   - Applies comparison criteria

3. Supplemental qualifier comparison (if supp=Y):
   - Checks for SUPP-- datasets
   - Verifies observation counts
   - Compares using standard SUPP keys
   - Processes only if data exists

4. Comments dataset comparison (if com=Y):
   - Checks for _comm datasets
   - Verifies observation counts
   - Compares using standard keys
   - Processes only if data exists

## Examples
```sas
/* Basic comparison of DM domain */
%kqucomp(base=DM, prod_lib=sdtm, supp=Y, com=Y);

/* Custom comparison with specific criteria */
%kqucomp(base=ADSL,
         qc=validation,
         id=studyid usubjid,
         prod_lib=adam,
         qc_lib=valid,
         crit=0.00001);

/* Compare only main dataset with default settings */
%kqucomp(base=VS,
         prod_lib=sdtm);
```

## Common Issues and Solutions
1. **Missing Parameters**
   - Error: "[parameter] is required parameter and should not be NULL"
   - Solution: Provide all required parameters

2. **Empty Datasets**
   - Issue: No comparison results for SUPP/comments
   - Solution: Verify datasets contain observations

3. **ID Variables**
   - Issue: Unexpected comparison results
   - Solution: Verify correct ID variables specified

## Notes and Limitations
1. Dataset handling:
   - Automatic SUPP-- dataset detection
   - Standard SDTM/ADaM naming conventions
   - Empty dataset handling
   - Library-specific processing

2. Comparison features:
   - Full dataset comparison
   - Supplemental qualifier support
   - Comments dataset support
   - Flexible ID variable specification

3. Performance considerations:
   - Processes only non-empty datasets
   - Separate comparisons for each component
   - Standard PROC COMPARE output

## Related Macros
- `%kqtlfcomp`: TLF dataset comparison
- `%xusupp`: Supplemental qualifier creation
- Other validation macros

## Change Log
### Version 1.0 (20AUG2021)
- Initial release
- Basic comparison functionality
- SUPP-- dataset support
- Comments dataset support 