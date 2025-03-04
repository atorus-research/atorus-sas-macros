# %xuloadcsv - CSV File Loading and Consolidation Utility

## Overview
The `%xuloadcsv` macro loads and combines multiple CSV files into a single SAS dataset. It supports regular expressions for file selection, handles variable naming, and can extract subject IDs and visit information from filenames. This is particularly useful for consolidating clinical data from multiple source files.

## Version Information
- **Version**: 1.0
- **Last Updated**: 18JUL2022
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No macro dependencies
- Requires access to source CSV files

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| filename | Yes | - | Regular expression to filter source files |
| filepath | No | [project path]/final/raw/external | Path to CSV files |
| splitchar | No | $ | CSV delimiter character |
| datarow | No | 2 | First row of data (after headers) |
| subjid | No | - | Regex to extract subject ID from filename |
| visit | No | - | Regex to extract visit from filename |
| outds | No | raw_all | Output dataset name |
| getnames | No | yes | Whether to use first row as variable names |
| compress_names | No | Y | Whether to remove spaces from variable names |
| debug | No | N | Whether to retain temporary datasets |

## Return Values/Output
Creates a consolidated dataset containing:
- Combined data from all matching CSV files
- Optional derived variables:
  - dataset_no: Sequential number for source file
  - subjid_derived: Extracted subject ID (if subjid specified)
  - visit_derived: Extracted visit (if visit specified)
- Standardized variable lengths across files

## Processing Details
1. File Selection:
   - Uses regex to filter files in directory
   - Excludes Excel files (xlsx, xlt)
   - Extracts metadata from filenames

2. Variable Processing:
   - Handles header rows if present
   - Standardizes variable names
   - Determines optimal variable lengths
   - Converts all variables to character initially

3. Data Consolidation:
   - Imports each file sequentially
   - Applies consistent variable attributes
   - Combines data with metadata
   - Handles missing or empty files

## Examples

### Basic Usage
```sas
%xuloadcsv(filename=%str(Clamp), subjid=%str(101-\d{3}), visit=%str(D\d+));
```

### Exclude Specific Files
```sas
%xuloadcsv(filename=%str(^(?!.*(Dummy|PC|PK)).*csv$));
```

### Custom Settings
```sas
%xuloadcsv(
    filename=%str(LAB.*\.csv),
    splitchar=",",
    datarow=3,
    compress_names=N,
    outds=combined_labs
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| No files found | Check regex pattern and filepath |
| Variable name conflicts | Use compress_names=Y or adjust source headers |
| Misaligned data | Verify datarow setting matches file structure |

## Notes and Limitations
- All files must share similar structure
- Initial import treats all variables as character
- Variable lengths are maximized across all files
- Regex patterns must follow SAS PRX syntax
- Excel files are automatically excluded
- Header handling requires consistent structure
- Maximum filename length for extracted values is 200

## Related Macros
- xuload.sas - For loading SAS datasets
- Other data import utilities
- File handling macros

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 18JUL2022 | Atorus Research | Initial version | 