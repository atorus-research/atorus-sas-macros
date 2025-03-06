# %xtcore

## Overview
The `%xtcore` macro adds ADSL core variables to an analysis dataset based on metadata specifications. It identifies core variables from the metadata, handles potential variable name conflicts, and ensures consistent subject-level information across analysis datasets.

## Version Information
- Version: 1.0
- Last Updated: 14JUL2022
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Datasets:
  - ADSL dataset in ADAM library
  - Parent analysis dataset
- Required Files:
  - ADaM specification metadata file (default: `ADAM_spec_Variables.csv`)

## Parameters
- **inds** (required): Name of the parent dataset to add ADSL core variables to.
- **outds** (optional): Name of the output dataset. Default: value of `inds`.
- **filename** (optional): Name of the metadata specification file. Default: `ADAM_spec_Variables.csv`.
- **filepath** (optional): Path to the metadata specification file. Default: `[project path]/final/specs`.
- **debug** (optional): Flag determining whether to retain temporary datasets. Default: N.

## Return Values/Output
- Creates a dataset containing:
  - All variables from the parent dataset (excluding duplicated core variables)
  - Core variables from ADSL as specified in metadata
- Creates global macro variable:
  - `core_vars`: Space-separated list of core variables from ADSL
- Log messages for processing status and any errors

## Processing Details
1. Parameter validation:
   - Checks for required parameters
   - Verifies metadata file existence
   - Validates parameter values

2. Metadata processing:
   - Imports metadata specification file
   - Identifies ADSL core variables (where core="Y")
   - Creates global variable list
   - Identifies overlapping variables between parent and ADSL

3. Data merging:
   - Sorts datasets by USUBJID
   - Removes duplicate core variables from parent dataset
   - Merges parent dataset with ADSL core variables
   - Retains only matched subjects

## Examples
```sas
/* Basic usage - add core variables to ADLB */
%xtcore(adlb);

/* Specify custom output dataset */
%xtcore(adae, outds=adae_core);

/* Use custom metadata file */
%xtcore(adtte, 
        filename=study_spec_Variables.csv,
        filepath=/path/to/specs);

/* Keep temporary datasets for debugging */
%xtcore(adsl, debug=Y);
```

## Common Issues and Solutions
1. **Missing Metadata File**
   - Error: "input [filename] file was not found in [filepath]"
   - Solution: Verify metadata file exists and path is correct

2. **Missing ADSL Dataset**
   - Issue: Unable to merge core variables
   - Solution: Ensure ADSL exists in ADAM library

3. **Duplicate Variables**
   - Issue: Core variables already exist in parent dataset
   - Solution: Macro automatically handles by using ADSL versions

## Notes and Limitations
1. The macro assumes:
   - ADSL exists in the ADAM library
   - Metadata file follows standard structure with required columns:
     - dataset
     - variable
     - core
     - order
2. Core variables from parent dataset are replaced with ADSL versions
3. Only records with matching USUBJID in both datasets are retained
4. STUDYID and USUBJID are always preserved from parent dataset

## See Also
- [`%xtmeta`](/man/global/xtmeta.md): Processes metadata specifications
- [`%xtorder`](/man/global/xtorder.md): Orders variables according to metadata
- [`%kutitles`](/man/study_specific/kutitles.md): Title and footnote management

## Change Log
### Version 1.0 (14JUL2022)
- Initial release
- Basic core variable merging functionality
- Automatic handling of duplicate variables
- Global variable list creation 