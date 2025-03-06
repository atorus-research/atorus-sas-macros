# %xumprint - Log and Output Management Utility

## Overview
The `%xumprint` macro manages SAS log and listing file handling, providing functionality to save these files to specific directories and reload logs back into SAS sessions. It also enhances log readability by converting certain notes of interest into warnings. The macro acts as a wrapper (like DO-END blocks) and should be called at both the start and end of SAS programs.

## Version Information
- **Version**: 1.0
- **Last Updated**: 19FEB2021
- **Author(s)**: Atorus Research

## Dependencies
- SAS version: SAS 9.4 V9
- Required macros:
  - xuprogpath.sas - For creating task and program-related globals
  - setup.sas - For assigning required libnames and sasautos
- Required global variables (when route=YES):
  - __p_name: Program name (created automatically by xuprogpath.sas)
  - __log_path: Path to log folder (created automatically by xuprogpath.sas)
  - __lst_path: Path to outputs folder (created automatically by xuprogpath.sas)

## Parameters
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| route | No | NO | Controls file handling mode. YES saves output lst and log files, NO uploads log back to SAS EG |

## Return Values/Output
- When route=YES:
  - Creates .log and .lst files in task-specific directories
  - Cleans macro cache before execution
  - Sets up program environment
- When route=NO:
  - Displays modified log in SAS EG
  - Converts certain notes to warnings
  - Restores original SAS options

## Processing Details
1. Input Validation:
   - Verifies route parameter is either YES or NO
   - Checks for required global variables when route=YES

2. When route=YES:
   - Cleans macro cache (deletes previously resolved macros)
   - Calls xuprogpath for task/program globals
   - Redirects output to specified files
   - Includes [`setup.sas`](/man/study_specific/setup.md) for environment configuration

3. When route=NO:
   - Restores default output destinations
   - Reads and modifies log file content
   - Enhances log readability by:
     - Converting NOTE xxx-xxx to NOTE:
     - Elevating certain notes to warnings
   - Restores original SAS options

## Examples

### Program Start
```sas
%xumprint(route=YES);
```

### Program End
```sas
%xumprint();
```

## Common Issues and Solutions
| Issue | Solution |
|-------|----------|
| Missing global variables | Ensure program is saved and xuprogpath.sas is called |
| Macro cache conflicts | Use route=YES at program start to clean cache |
| Log file not found | Verify correct path and program name globals |

## Notes and Limitations
- Program must be saved for route=YES to work
- Macro cache cleaning only affects standardized prefix macros
- Log modification only occurs when reading back to SAS EG
- Specific notes are automatically elevated to warnings:
  - Uninitialized variables
  - Invalid operations
  - Division by zero
  - Graph legend constraints
  - Format size issues
  - Merge statement repeats
  - Missing value operations
  - Loading failures
  - Data type conversions

## See Also
- [`%xuprogpath`](/man/global/xuprogpath.md) - Program path management
- [`setup.sas`](/man/study_specific/setup.md) - For assigning required libnames and sasautos
- Other logging and output management macros

## Change Log
| Version | Date | Author | Changes |
|---------|------|---------|---------|
| 1.0 | 19FEB2021 | Atorus Research | Initial version | 