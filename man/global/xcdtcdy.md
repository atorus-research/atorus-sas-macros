# %xcdtcdy - Calculate Study Day from ISO 8601 Dates

## Overview
The `%xcdtcdy` macro calculates the study day (--DY) variable from two SDTM character date variables in ISO 8601 format (--DTC). This is commonly used in clinical trials to calculate the number of days between a reference date (usually study start) and another event date.

## Version Information
- **Version**: 1.0
- **Last Updated**: 19FEB2021
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Input dates must be in ISO 8601 format (YYYY-MM-DD)
- No other macro dependencies

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| dtcdate | Yes | - | Name of the character --DTC variable to calculate --DY for |
| refdate | Yes | - | Name of the reference character date variable |

## Return Values/Output
The macro creates:
- A numeric --DY variable with the same prefix as the input dtcdate variable
  (e.g., if dtcdate=AESTDTC, creates AESTDY)
- Error messages in the log for invalid date formats or missing parameters

## Processing Details
1. Input Validation:
   - Checks if both required parameters are provided
   - Validates that dates don't contain invalid characters (only 'T' is allowed)
   - Ensures both dates have at least 10 characters (full date portion)

2. Date Processing:
   - Extracts the first 10 characters (date portion) from both dates
   - Converts ISO 8601 dates to SAS dates using e8601da. format
   - Calculates study day using the formula: DY = date - refdate + (date >= refdate)

3. Error Handling:
   - Outputs error messages for missing parameters
   - Outputs error messages for invalid date characters
   - Skips processing if dates are incomplete

## Examples

### Basic Usage
```sas
%xcdtcdy(exstdtc, rfstdtc);
```

### Lab Data Example
```sas
%xcdtcdy(lbdtc, rfstdtc);
```

### Multiple Calls Example
```sas
data ae;
    set ae;
    %xcdtcdy(aestdtc, rfstdtc);
    %xcdtcdy(aeendtc, rfstdtc);
run;
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Invalid characters in dates | Remove any alphabetic characters except 'T' from the dates |
| Missing study days | Ensure both dates have at least the date portion (YYYY-MM-DD) |
| Incorrect day calculation | Verify that the reference date is the correct anchor date |

## Notes and Limitations
- Only processes dates with at least 10 characters (full date portion)
- Ignores time components if present
- Study day 1 is the day of the reference date
- Positive study days include the reference date
- Does not handle partial dates

## Related Macros
- xcdtc2dt.sas - For converting ISO dates to SAS dates/times
- Other date handling macros in the global library

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 19FEB2021 | Atorus Research | Initial version | 