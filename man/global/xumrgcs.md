# %xumrgcs

## Overview
The `%xumrgcs` macro merges Supplemental Qualifiers (SUPP--) and Comments (CO) datasets with their parent SDTM datasets. It handles multiple input datasets, automatically determines identifier variables and their types, and performs appropriate data type conversions for merging.

## Version Information
- Version: 1.0
- Last Updated: 22AUG2022
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Datasets:
  - Parent SDTM dataset(s) in the source library
  - SUPP-- datasets (if supp=Y)
  - CO dataset (if co=Y)
- No macro dependencies

## Parameters
- **inds** (required): Space-separated list of input dataset names to process.
- **sourcelib** (required): Name of the library containing input datasets.
- **supp** (optional): Flag determining whether to merge SUPP-- datasets. Default: Y.
- **co** (optional): Flag determining whether to merge CO dataset. Default: Y.
- **debug** (optional): Flag determining whether to retain temporary datasets. Default: N.

## Return Values/Output
- Creates new datasets with naming convention:
  - `[dataset]_supp` when only SUPP-- is merged
  - `[dataset]_co` when only CO is merged
  - `[dataset]_supp_co` when both are merged
- Output datasets contain:
  - All variables from the parent dataset
  - Transposed supplemental qualifier variables (if supp=Y)
  - Comment variables (COVALx) for the domain (if co=Y)
- Log messages for processing status and any errors

## Processing Details
1. Parameter validation:
   - Checks for required parameters
   - Validates Y/N flags
   - Ensures at least one of supp/co is Y
2. For each input dataset:
   - Verifies dataset existence
   - Gets domain name from dataset
3. SUPP-- processing (if supp=Y):
   - Identifies IDVAR and its type
   - Transposes SUPP-- data by QNAM
   - Converts IDVARVAL to match parent dataset type
   - Merges with parent dataset
4. CO processing (if co=Y):
   - Filters CO for relevant domain
   - Identifies IDVAR and its type
   - Converts IDVARVAL to match parent dataset type
   - Merges with parent or SUPP-merged dataset

## Examples
```sas
/* Merge both SUPP and CO for LB and AE domains */
%xumrgcs(lb ae, sdtm, supp=Y, co=Y);

/* Merge only SUPP for PR domain */
%xumrgcs(pr, sdtm, supp=Y, co=N);

/* Merge only CO for multiple domains with debug mode */
%xumrgcs(ae cm vs, sdtm, supp=N, co=Y, debug=Y);
```

## Common Issues and Solutions
1. **Missing Supplemental Dataset**
   - Error: "SUPP[domain] was not found in [library] library"
   - Solution: Verify SUPP-- dataset exists for the domain

2. **Missing CO Dataset**
   - Error: "CO was not found in [library] library"
   - Solution: Ensure CO dataset exists in the source library

3. **No Comments for Domain**
   - Warning: "CO has no comments for [domain] domain"
   - Solution: Verify if comments are expected for the domain

## Notes and Limitations
1. Both supp and co parameters cannot be N simultaneously.
2. The macro handles both character and numeric ID variables automatically.
3. For SUPP-- merging, each domain must have its corresponding SUPP[domain] dataset.
4. For CO merging, a single CO dataset contains comments for all domains.
5. Output dataset names reflect the types of data merged.

## See Also
- [`%xusupp`](/man/global/xusupp.md): Creates supplemental qualifier datasets
- [`%xuload`](/man/global/xuload.md): Loads SDTM datasets
- [`%xusplit`](/man/global/xusplit.md): Splits datasets by specified criteria

## Change Log
### Version 1.0 (22AUG2022)
- Initial release
- Support for multiple input datasets
- Automatic handling of ID variable types
- Flexible SUPP/CO merging options 