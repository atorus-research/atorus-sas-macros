# %xcdtc2dt - Convert ISO 8601 Date/Time Character Variables to SAS Date/Time Values

## Overview
The `%xcdtc2dt` macro converts character ISO 8601 formatted date/time variables (--DTC) into SAS analysis date (-DT), time (-TM), and datetime (-DTM) variables. Additionally, it can create a relative day variable (-DY) when a reference date is provided.

## Version Information
- **Version**: 1.0
- **Last Updated**: 19FEB2021
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- No other macro dependencies
- Input must be in ISO 8601 format (YYYY-MM-DDThh:mm:ss)

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| dtcdate | Yes | - | Name of the input --DTC variable in ISO 8601 format |
| prefix | No | a | Prefix for the output analysis variables (-DT, -TM, -DTM, -DY) |
| refdate | No | - | Numeric reference date for calculating relative days |

## Return Values/Output
The macro creates the following variables (where 'prefix' is the specified prefix):
- **prefixDT**: SAS date value
- **prefixTM**: SAS time value (only if time component is present)
- **prefixDTM**: SAS datetime value (only if time component is present)
- **prefixDY**: Relative day number (only if refdate is specified)

## Processing Details
1. Input Validation:
   - Checks if required parameter (dtcdate) is provided
   - Validates length of input date string

2. Date/Time Processing:
   - For dates without time (length 10): converts to SAS date
   - For dates with time (length 16 or 19): converts to SAS datetime and splits into date and time components

3. Relative Day Calculation:
   - If reference date is provided, calculates days between dates
   - Uses formula: DY = date - refdate + (date >= refdate)

## Examples

### Basic Usage - Date Only
```sas
%xcdtc2dt(aestdtc, prefix=ast);
```

### Usage with Reference Date
```sas
%xcdtc2dt(aestdtc, prefix=ast, refdate=trtsdt);
```

### Advanced Usage with Custom Prefix
```sas
%xcdtc2dt(
    dtcdate=visitdtc,
    prefix=vst,
    refdate=studystdt
);
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Invalid date format | Ensure input date is in ISO 8601 format (YYYY-MM-DD) |
| Missing relative days | Check if both input date and reference date are non-missing |
| Partial dates | Only the date portion will be converted, time variables will not be created |

## Notes and Limitations
- Input must be in ISO 8601 format
- Handles both partial (date only) and complete (date and time) timestamps
- Time component must be complete if present (partial times are treated as date-only)
- Relative day calculation accounts for same-day events (adds 1 for dates >= reference)

## See Also
- [`%xcdtcdy`](/man/global/xcdtcdy.md): For relative day calculations
- [`%xudt2dtc`](/man/global/xudt2dtc.md): Convert SAS dates to ISO 8601 format
- [`%xuvisit`](/man/global/xuvisit.md): Visit and timing derivations

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 19FEB2021 | Atorus Research | Initial version | 