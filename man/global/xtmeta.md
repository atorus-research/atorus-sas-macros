# %xtmeta

## Overview
The `%xtmeta` macro creates a zero-record dataset based on metadata specifications and generates a global macro variable containing the dataset's variable list. It supports both SDTM and ADaM datasets, automatically determining the appropriate metadata source and handling variable attributes according to specifications.

## Version Information
- Version: 1.0
- Last Updated: 20JUL2022
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Files:
  - SDTM or ADaM specification metadata file (CSV format)
  - For SDTM: `SDTM_spec_Variables.csv`
  - For ADaM: `ADAM_spec_Variables.csv`
- No macro dependencies

## Parameters
- **dsname** (required): Name of the dataset to look for in the metadata file.
- **filename** (optional): Name of the CSV metadata file. If not specified, automatically determined based on dataset name:
  - SDTM for 2-character domains, SUPP--, RELREC, or AP-- datasets
  - ADaM for all other datasets
- **filepath** (optional): Path to the metadata file. Default: `[project path]/final/specs`.
- **qc** (optional): Flag to set all character variable lengths to 200. Default: N.
- **debug** (optional): Flag to retain temporary datasets. Default: N.

## Return Values/Output
- Creates a zero-record dataset named `EMPTY_[dsname]` containing:
  - All variables specified in metadata
  - Variable attributes (labels, lengths, formats)
  - No observations
- Creates a global macro variable `[dsname]KEEPSTRING` containing:
  - Space-separated list of variables in metadata order
- Log messages for processing status and any errors

## Processing Details
1. Parameter validation:
   - Checks for required parameters
   - Determines appropriate metadata file
   - Verifies file existence

2. Metadata processing:
   - Imports metadata specification
   - Filters for specified dataset
   - Sorts variables by specified order
   - Validates variable lengths

3. Variable attribute handling:
   - Maps metadata data types to SAS types
   - Sets variable lengths (standard or QC mode)
   - Assigns labels and formats
   - Creates keepstring variable list

## Examples
```sas
/* Basic usage - create empty ADSL structure */
%xtmeta(ADSL);

/* Create SDTM DM structure with QC lengths */
%xtmeta(DM, qc=Y);

/* Use custom metadata file */
%xtmeta(ADAE, 
        filename=study_spec_Variables.csv,
        filepath=/path/to/specs);

/* Keep temporary datasets for debugging */
%xtmeta(ADLB, debug=Y);
```

## Common Issues and Solutions
1. **Missing Metadata File**
   - Error: "input [filename] file was not found in [filepath]"
   - Solution: Verify metadata file exists and path is correct

2. **Dataset Not in Metadata**
   - Error: "[dsname] does not exist in [filename]"
   - Solution: Verify dataset name and metadata content

3. **Missing Variable Lengths**
   - Note: "Length is not filled for [variables]"
   - Solution: Review metadata and fill in missing lengths

4. **Unexpected Variable's Value Retain**
   - Occurs when: set the EMPTY_[dsname] with a non-empty dataset, and do some further data processing in the same datastep
   - Solution: separate the setting of the data from the postprocessing into two datasteps.
   </br>Examples:
   ```sas
   /* This will cause an issue: */
   data <dataset_name>;
      set &empty._domain <rawdata>;
      <data processing statements>;
   run;

   /* Correct use: */
   data <dataset_name>;
      set &empty_domain. <rawdata>;
   run;

   data <dataset_name_1>;
      set <dataset_name>;
      <data processing statements>;
   run;
   ```
5. **Erroneous assumption the ADaM metadata is being used when it is not**.
   - Occurs when: used for the "spit" datasets (LBSA, LBPD, LBCHEM, etc.) the macro assumes it is ADaM dataset, because the name exceeds two characters (SUPPXX datasets and RELREC are special cases and are accounted for)
   - Solution: explicitly specify SDTM metadata file name in corresponding macro parameter.

## Notes and Limitations
1. Metadata file must follow standard structure with required columns:
   - dataset
   - variable
   - order
   - label
   - "Data Type"
   - length
   - "Use (y)"
   - format (for ADaM)

2. Supported data types:
   - Numeric: INTEGER, FLOAT
   - Character: TEXT, DATETIME, DATE, TIME, etc.

3. Variable length handling:
   - Default lengths: 8 for numeric, 200 for character if not specified
   - QC mode forces all character lengths to 200
   - Numeric lengths always 8

4. Format assignments only processed for ADaM datasets

## See Also
- [`%xtcore`](/man/global/xtcore.md): Uses metadata for core variable processing
- [`%xtorder`](/man/global/xtorder.md): Orders variables according to metadata
- [`%kutitles`](/man/study_specific/kutitles.md): Title and footnote management

## Change Log
### Version 1.0 (20JUL2022)
- Initial release
- Automatic metadata file selection
- QC mode for character lengths
- Support for SDTM and ADaM specifications 