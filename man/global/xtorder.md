# %xtorder

## Overview
The `%xtorder` macro creates a global macro variable containing the sort order for a dataset based on metadata specifications. It automatically determines whether to use SDTM or ADaM metadata and extracts the key variables that define the dataset's sort order.

## Version Information
- Version: 1.0
- Last Updated: 20JUL2022
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Files:
  - SDTM or ADaM specification metadata file (CSV format)
  - For SDTM: `SDTM_spec_Datasets.csv`
  - For ADaM: `ADAM_spec_Datasets.csv`
- No macro dependencies

## Parameters
- **dsname** (required): Name of the dataset to look for in the metadata file.
- **filename** (optional): Name of the CSV metadata file. If not specified, automatically determined based on dataset name:
  - SDTM for 2-character domains, SUPP--, RELREC, or AP-- datasets
  - ADaM for all other datasets
- **filepath** (optional): Path to the metadata file. Default: `[project path]/final/specs`.
- **debug** (optional): Flag to retain temporary datasets. Default: N.

## Return Values/Output
- Creates a global macro variable `[dsname]SORTSTRING` containing:
  - Space-separated list of key variables defining the dataset's sort order
  - Extracted from the "Key Variables" column in metadata
- Log messages for processing status and any errors

## Processing Details
1. Parameter validation:
   - Checks for required parameters
   - Determines appropriate metadata file
   - Verifies file existence

2. Metadata processing:
   - Imports metadata specification
   - Filters for specified dataset
   - Extracts key variables information

3. Sort string creation:
   - Processes "Key Variables" column
   - Converts comma-separated list to space-separated
   - Creates global macro variable

## Examples
```sas
/* Basic usage - get sort order for ADSL */
%xtorder(ADSL);
%put &ADSLSORTSTRING;  /* Example output: STUDYID USUBJID */

/* Get sort order for SDTM domain */
%xtorder(DM);
%put &DMSORTSTRING;    /* Example output: STUDYID USUBJID */

/* Use custom metadata file */
%xtorder(ADAE, 
         filename=study_spec_Datasets.csv,
         filepath=/path/to/specs);

/* Keep temporary datasets for debugging */
%xtorder(ADLB, debug=Y);
```

## Common Issues and Solutions
1. **Missing Metadata File**
   - Error: "input [filename] file was not found in [filepath]"
   - Solution: Verify metadata file exists and path is correct

2. **Dataset Not in Metadata**
   - Error: "[dsname] does not exist in [filename]"
   - Solution: Verify dataset name and metadata content

3. **Missing Key Variables**
   - Issue: Empty SORTSTRING created
   - Solution: Check "Key Variables" column in metadata
   
4. **Erroneous assumption the ADaM metadata is being used when it is not**.
   - Occurs when: used for the "spit" datasets (LBSA, LBPD, LBCHEM, etc.) the macro assumes it is ADaM dataset, because the name exceeds two characters (SUPPXX datasets and RELREC are special cases and are accounted for)
   - Solution: explicitly specify SDTM metadata file name in corresponding macro parameter.

## Notes and Limitations
1. Metadata file must follow standard structure with required columns:
   - dataset
   - "Key Variables"

2. The macro assumes:
   - Key variables are listed in the correct order
   - Variables are comma-separated in metadata
   - Variable names are valid SAS names

3. The resulting sort string:
   - Has commas replaced with spaces
   - Contains no leading/trailing spaces
   - Preserves the order specified in metadata

4. No validation is performed on:
   - Existence of key variables in dataset
   - Validity of variable names
   - Duplicate variables in sort order

## See Also
- [`%xtmeta`](/man/global/xtmeta.md): Creates dataset structure from metadata
- [`%xtcore`](/man/global/xtcore.md): Uses metadata for core variable processing
- [`%xdalign`](/man/global/xdalign.md): Aligns datasets with metadata specifications

## Change Log
### Version 1.0 (20JUL2022)
- Initial release
- Automatic metadata file selection
- Support for SDTM and ADaM specifications
- Basic sort string generation 