# %kudlen

## Overview
The `%kudlen` macro optimizes variable lengths in a dataset by adjusting character variable lengths to match the maximum length of their actual values. This helps reduce memory usage and improve efficiency while preserving all data content, labels, and formats.

## Version Information
- Version: 1.0
- Last Updated: 20AUG2021
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Required Macros:
  - `%xurnm`: Variable renaming utility

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| inds | Yes | - | Input dataset name |
| outds | No | `&inds` | Output dataset name |
| debug | No | N | Flag to retain temporary datasets |

## Return Values/Output
- Creates a new dataset with:
  - Optimized character variable lengths
  - Preserved variable attributes:
    - Labels
    - Formats
    - Informats
  - Unchanged numeric variables
  - Original data values
- Log messages indicating:
  - Processing status
  - Parameter validation
  - Error conditions

## Processing Details
1. Parameter validation:
   - Checks required parameters
   - Verifies dataset existence
   - Validates parameter values

2. Metadata analysis:
   - Extracts variable information
   - Identifies character variables
   - Preserves variable attributes
   - Maintains variable order

3. Length optimization:
   - Calculates maximum length per variable
   - Processes only character variables
   - Maintains minimum length of 1
   - Preserves numeric lengths

4. Dataset recreation:
   - Applies optimized lengths
   - Restores variable attributes
   - Maintains data integrity
   - Cleans up temporary files

## Examples
```sas
/* Basic usage - optimize current dataset */
%kudlen(dm);

/* Create new optimized dataset */
%kudlen(ae,
        outds=ae_opt);

/* Debug mode for troubleshooting */
%kudlen(lb,
        outds=lb_opt,
        debug=Y);
```

## Common Issues and Solutions
1. **Missing Parameters**
   - Error: "[parameter] is required parameter and should not be NULL"
   - Solution: Provide required parameters

2. **Memory Issues**
   - Issue: Large datasets with many variables
   - Solution: Process in smaller chunks

3. **Variable Attributes**
   - Issue: Lost formats or labels
   - Solution: Verify metadata preservation

## Notes and Limitations
1. Variable processing:
   - Only optimizes character variables
   - Preserves numeric variable lengths (8 bytes)
   - Maintains minimum length of 1
   - Retains original variable order

2. Attribute handling:
   - Preserves variable labels
   - Maintains formats and informats
   - Keeps variable names
   - Retains metadata properties

3. Performance considerations:
   - Creates temporary datasets
   - Memory usage during processing
   - Multiple metadata operations
   - Sequential processing

## Related Macros
- `%xurnm`: Variable renaming
- `%xuload`: Dataset loading
- Other data management macros

## Change Log
### Version 1.0 (20AUG2021)
- Initial release
- Basic length optimization
- Attribute preservation
- Debug mode support 