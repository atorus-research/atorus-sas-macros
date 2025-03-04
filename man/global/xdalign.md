# %xdalign - Decimal Alignment for PDF/RTF Output

## Overview
The `%xdalign` macro provides proper decimal alignment in PDF or RTF outputs by adding appropriate spacing before numbers. This ensures that decimal points are aligned vertically in tables and reports, improving readability and professional appearance.

## Version Information
- **Version**: 1.0
- **Last Updated**: 05MAY2021
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No other macro dependencies
- Requires output to be either PDF or RTF format

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| invar | Yes | - | Input variable name containing the numbers to align |
| type | No | RTF | Output type (PDF or RTF) |
| escapechar | No | $ | Escape character used for formatting |
| len | No | 6 | Total length of the output field, including indentation |

## Return Values/Output
- Modifies the input variable (`invar`) by adding appropriate spacing for decimal alignment
- Warning messages in the log for numbers with integer parts longer than 5 digits

## Processing Details
1. Input Validation:
   - Checks if required parameters are provided
   - Validates output type is either PDF or RTF
   - Verifies length parameter is specified

2. Alignment Processing:
   - Determines the length of the integer part (before decimal)
   - Adds appropriate spacing based on output type:
     - PDF: Uses nbspace formatting
     - RTF: Uses repeated escape characters

3. Error Handling:
   - Outputs error for invalid output types
   - Warns if integer part is longer than 5 digits
   - Validates required parameters

## Examples

### Basic Usage for RTF
```sas
%xdalign(trt_1, type=RTF, len=6);
```

### PDF Output with Custom Length
```sas
%xdalign(
    invar=mean_val,
    type=PDF,
    len=8,
    escapechar=$
);
```

### Multiple Variables in a Data Step
```sas
data report;
    set stats;
    %xdalign(n_mean, type=PDF, len=8);
    %xdalign(n_median, type=PDF, len=8);
    %xdalign(std_dev, type=PDF, len=8);
run;
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Misaligned decimals | Ensure len parameter accounts for largest possible number |
| Numbers too large | Increase len parameter or format numbers to have fewer digits |
| Formatting not appearing | Verify correct escape character is used for your template |

## Notes and Limitations
- Maximum supported integer length is 5 digits
- Only supports PDF and RTF output types
- Assumes decimal numbers (will still work with integers but spacing may be off)
- Length parameter must include space for both integer and decimal parts
- Warning will be issued for numbers with more than 5 digits before decimal point

## See Also
- [`%xufmt`](/man/global/xufmt.md) - For general formatting utilities
- Other formatting and reporting macros in the global library

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 05MAY2021 | Atorus Research | Initial version | 