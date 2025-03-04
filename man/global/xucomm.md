# %xucomm - Create SDTM Comments (CO) Domain Records

## Overview
The `%xucomm` macro creates SDTM Comments (CO) domain records from source datasets. It processes comments from any SDTM domain and creates standardized CO records following CDISC SDTM standards, with proper sequencing and handling of multiple comment lines.

## Version Information
- **Version**: 1.0
- **Last Updated**: 15JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Requires the following macros:
  - xtmeta.sas - For CO domain metadata
  - xtorder.sas - For sorting specifications
  - xusplit.sas - For splitting comment text
- Global macro variable `&domain` must be defined before macro call

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Name of the input dataset containing comments |
| invar | Yes | - | Name of the input variable containing comment text |
| idvar | No | domainseq | Name of the ID variable (ignored for DM domain) |
| qc | No | N | Set to Y if macro is used for QC purposes |
| debug | No | N | Set to Y to retain temporary datasets |

## Return Values/Output
Creates a dataset named:
- `sdtm.domain_comm` if qc=N
- `qcdomain_comm` if qc=Y

Output dataset contains standard CO domain variables:
- STUDYID, RDOMAIN, USUBJID
- IDVAR, IDVARVAL (when applicable)
- COSEQ
- COVAL1-COVALn (as needed for long comments)

## Processing Details
1. Input Validation:
   - Verifies required parameters
   - Checks for &domain macro variable
   - Validates IDVAR handling for DM domain

2. Comment Processing:
   - Splits comments into multiple lines if needed
   - Creates appropriate number of COVALx variables
   - Handles both character and numeric ID variables

3. Sequence Generation:
   - Creates COSEQ within USUBJID
   - Ensures proper sorting of output records
   - Removes duplicates

## Examples

### Basic Usage for DM Domain
```sas
%let domain = DM;
%xucomm(dm, dmcomm);
```

### Usage with ID Variable
```sas
%let domain = LB;
%xucomm(qclb, lbcomm, idvar=lbseq, qc=Y);
```

### Debug Mode
```sas
%let domain = AE;
%xucomm(
    inds=ae,
    invar=aecomm,
    idvar=aeseq,
    debug=Y
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing domain variable | Define %let domain=XX before macro call |
| Duplicate comments | Check input data for duplicates |
| Missing metadata | Ensure xtmeta macro has CO domain specifications |

## Notes and Limitations
- Requires pre-defined &domain macro variable
- DM domain has special handling (no IDVAR/IDVARVAL)
- Comments are automatically split if they exceed COVALx length
- Warns if more COVALx variables are needed than specified in metadata
- QC mode creates separate output dataset with 'qc' prefix

## Related Macros
- xtmeta.sas - For metadata handling
- xtorder.sas - For sorting specifications
- xusplit.sas - For text splitting
- Other SDTM utility macros

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 15JUL2022 | Atorus Research | Initial version | 