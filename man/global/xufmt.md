# %xufmt - Create SAS Formats from Specification Codelists

## Overview
The `%xufmt` macro creates SAS formats from codelists defined in SDTM or ADaM specifications. It generates bidirectional formats for terms, decoded values, and order numbers, enabling flexible data transformations and labeling.

## Version Information
- **Version**: 1.0
- **Last Updated**: 13JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Required files:
  - SDTM_spec_Codelists.csv or ADaM_spec_Codelists.csv
- No macro dependencies

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| fmt | Yes | - | Space-separated list of codelist names to create formats for |
| filename | Yes | - | Source file name (SDTM_spec_Codelists.csv or ADaM_spec_Codelists.csv) |
| filepath | No | [project path]/final/specs | Path to the source file |
| debug | No | N | Whether to retain temporary datasets (Y/N) |

## Return Values/Output
Creates the following SAS formats for each codelist:
- `IDxx` formats where ID is the codelist name and xx is the conversion type:
  - OT: Order to Term
  - TO: Term to Order
  - OD: Order to Decoded value
  - DO: Decoded value to Order
  - DT: Decoded value to Term
  - TD: Term to Decoded value

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Checks source file existence
   - Validates codelist name lengths (≤ 29 characters)

2. Format Creation:
   - Imports codelist metadata
   - Checks for non-printable characters
   - Creates bidirectional formats for all combinations
   - Handles numeric and character conversions

3. Quality Control:
   - Removes duplicate format entries
   - Validates format uniqueness
   - Compresses dots in format names
   - Checks for non-printable characters

## Examples

### Basic Usage - Single Codelist
```sas
%xufmt(VSPARAM, ADaM_spec_Codelist.csv);
```

### Multiple Codelists
```sas
%xufmt(RACE SEX, SDTM_spec_Codelist.csv);
```

### Custom Path with Debug
```sas
%xufmt(
    fmt=SEVERITY,
    filename=SDTM_spec_Codelists.csv,
    filepath=/path/to/specs,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Invalid format names | Ensure codelist IDs are ≤ 29 characters |
| Non-printable characters | Clean source data of special characters |
| Duplicate mappings | Check codelist for unique term/decoded value pairs |

## Notes and Limitations
- Maximum codelist name length is 29 characters
- Dots in codelist names are compressed
- Non-printable characters cause term exclusion
- Creates multiple format types per codelist
- Only creates formats for unique mappings
- Format names are automatically generated from codelist ID

## Related Macros
- xuct.sas - For controlled terminology validation
- Other format and codelist handling macros
- Data standardization macros

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 13JUL2022 | Atorus Research | Initial version | 