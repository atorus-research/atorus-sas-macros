# autoexec.sas

## Overview
The `autoexec.sas` file is a system initialization script that sets up the environment for SAS program execution. It establishes global variables, paths, and options based on the operating system, and configures the programming environment for Atorus's standard directory structure.

## Version Information
- Version: 1.0
- Last Updated: 19FEB2021
- Author: Atorus Research

## Dependencies
- SAS Version: SAS 9.4 V9
- Operating Systems Supported:
  - Windows (WIN)
  - Sun Solaris (SUN 4, SUN 64)
  - Linux (LIN X64)
- No macro dependencies

## Parameters
None - This is an initialization script that runs automatically.

## Return Values/Output
Creates the following global variables:
- **`__root`**: Root directory path for projects
  - Windows: `F:\projects`
  - Unix/Linux: `/sambaShare/projects`
- **`II`**: Operating system-specific directory separator
  - Windows: `\`
  - Unix/Linux: `/`
- **`__sponsor_level`**: Flag indicating sponsor-level directory structure (Y/N)
- **`__prod_qc_separation`**: Flag indicating production/QC separation (Y/N)

Sets the following SAS options:
- `minoperator`: Enables macro "in" operator
- `mindelimiter=","`: Sets delimiter for macro "in" operator
- `mautosource`: Enables autocall macro facility
- `sasautos`: Adds global macro library to autocall path
- `validvarname=any`: Allows any valid variable names

## Processing Details
1. Environment initialization:
   - Enables required SAS options
   - Declares global variables
   - Sets default values

2. Operating system detection:
   - Identifies system type using `&sysscp`
   - Sets appropriate root path
   - Sets directory separator

3. Global macro setup:
   - Configures autocall macro facility
   - Sets path to global macro library
   - Enables flexible variable naming

## Examples
```sas
/* The file is executed automatically when placed in the SAS executable directory */
/* Manual execution if needed */
%include "[path_to_file]/autoexec.sas";

/* Example of resulting environment setup */
%put &=__root;      /* F:\projects or /sambaShare/projects */
%put &=II;          /* \ or / */
%put &=__sponsor_level;     /* Y */
%put &=__prod_qc_separation;  /* Y */

------------------------------------------------------------------------------------------------------------------
/* !!! ALMOST ALWAYS THE AUTOEXEC.SAS FILE THAT RESIDES IN THE SAME DIRECTORY AS SAS.EXE SHOULD CONTAIN AN INCLUDE STATEMENT REFERENCING THIS AUTOEXEC.SAS FILE, SO NO FURTHER INCLUDES ARE NEEDED IN OTHER PROGRAMS */
------------------------------------------------------------------------------------------------------------------
```

## Common Issues and Solutions
1. **Unsupported Operating System**
   - Error: "operating system [system] is not defined"
   - Solution: Add system-specific settings for new OS

2. **Incorrect Root Path**
   - Issue: Programs unable to find project files
   - Solution: Verify and update `__root` path for environment

3. **Missing Global Macros**
   - Issue: Unable to find utility macros
   - Solution: Verify path in `sasautos` option

## Notes and Limitations
1. File placement:
   - Should be placed in same directory as sas.exe
   - Will be executed automatically at SAS startup

2. Environment configuration:
   - Designed for specific directory structure
   - Assumes standard project organization
   - Supports both Windows and Unix-like systems

3. Global settings:
   - Sets organization-wide standards
   - Affects all subsequent program execution
   - Cannot be easily overridden

4. Macro library:
   - Assumes utility macros in `[root]/utils/func`
   - Uses standard SAS autocall facility
   - Preserves existing autocall paths

## Related Files
- Global utility macros in `[root]/utils/func`
- Project-specific setup files
- SAS configuration files

## Change Log
### Version 1.0 (19FEB2021)
- Initial release
- Basic environment setup
- Windows and Unix support
- Standard directory structure configuration 