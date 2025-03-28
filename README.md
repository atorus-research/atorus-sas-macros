# atorus-sas-macros
Atorus clinical SAS Programming Macros

The repo consists of two sections: SAS Global and SAS Study-specific standard codes.
</br>**Global** - are ones that set up the environment and/or can be used on any study without a need to modify them.
</br>**Study-specific** - are intended to be copied to and live within a particular study (or protocol) area. It is expected they may need some modifications from study to study, and thus it is anticipated
they'll be used by one side only (production or validation).

## Documentation
- [Global Macros Documentation](/man/global/)
- [Study-specific Macros Documentation](/man/study_specific/)

## 1. List of the SAS Codes with Short Descriptions
### 1.1. Global standard code
| Type          | Name       | Description                                                                                                                                                                                                                                       |
|---------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| General       | xucont     | Uploads the dataset   and executes the contents procedure.                                                                                                                                                                                        |
| General       | xufmt      | Uses a metadata file   to create SAS formats.                                                                                                                                                                                                     |
| General       | xuload     | Uploads datasets to   SAS working directory and removes formats/informats.                                                                                                                                                                        |
| General       | xuloadcsv  | Loads external data   files in CSV format into one dataset in the Work directory.                                                                                                                                                                 |
| General       | xumprint   | Calls xuprogpath and   does all setup for the program, including creating libnames and saving .log   and .lst files on the server.                                                                                                                |
| General       | xuprogpath | Creates global macro   variables for the paths to the program and log files, and information about   the task such as asset, protocol, task, level (development or final),   subfolders, side (production or validation), type (SDTM, ADaM, TFL). |
| General       | xurnm      | Renames all variables   in the dataset.                                                                                                                                                                                                           |
| General       | xusave     | Applies the keep   variables, sort order, dataset label, and saves the dataset permanently.                                                                                                                                                       |
| SDTM          | xcdtcdy    | Takes two --DTC dates   and calculates a study day (--DY) variable.                                                                                                                                                                               |
| SDTM          | xucomm     | Creates CO domain   records from the dataset.                                                                                                                                                                                                     |
| SDTM          | xuepoch    | Derives EPOCH   variable using the SE SDTM dataset.                                                                                                                                                                                               |
| SDTM          | xusupp     | Creates and adds   variables to SUPP-- domain.                                                                                                                                                                                                    |
| SDTM          | xuvisit    | Derives   VISIT/VISITNUM variables.                                                                                                                                                                                                               |
| ADaM          | xcdtc2dt   | Converts character   --DTC variable into numeric --DT --TM --DTM. Also calculates analysis --DY   variables.                                                                                                                                      |
| ADaM          | xtcore     | Uses a metadata file   to get the list of ADSL core variables, and then merges them from ADSL to the   input dataset.                                                                                                                             |
| ADaM          | xumrgcs    | Merges respective   SUPP-- and CO records to the input SDTM dataset.                                                                                                                                                                              |
| General CDISC | xtmeta     | Uses a metadata file   to create a zero-record dataset with all needed variables from spec and their   attributes, plus a macro variable with a list of variables to keep in the   final dataset.                                                 |
| General CDISC | xtorder    | Uses a metadata file   to create a macro variable with the sorting sequence for the dataset.                                                                                                                                                      |
| General CDISC | xuct       | Checks if a variable   has only the values specified in the metadata file and checks values for   compliance with CDISC Controlled terminology.                                                                                                   |
| General CDISC | xuseq      | Creates --SEQ   variable using the sorting sequence from the metadata file.                                                                                                                                                                       |
| General CDISC | xusplit    | Splits long text   variable into multiple shorter sub-variables.                                                                                                                                                                                  |
| Displays      | xdalign    | Adds leading spaces   to decimal-align variable values in data displays.                                                                                                                                                                          |

### 1.2. Study-specific code
| Type              | Name       | Description                                                                                                                                                         |
|-------------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Displays          | jdtflstyle | A style template macro for study   PDF/RTF outputs. Opens ODS PDF/RTF destination and creates PDF/RTF file.   Also, creates global macro variables with timestamps. |
| Displays          | kdident    | Split long text into several   lines with indentation, if required.                                                                                                 |
| QC, Displays      | kqtlfcomp  | Nice and robust TFL datasets   compare macro.                                                                                                                       |
| QC, General CDISC | kqucomp    | SDTM and ADaM datasets compare   macro.                                                                                                                             |
| General CDISC     | kudlen     | Set the variable length to the   maximum length met for this variable within the dataset.                                                                           |
| Displays          | kutitles   | Macro which assigns titles   according to the external TFL_titles.csv file.                                                                                         |
| Displays          | koutrtf   | Macro which generates Table/Listing RTF out of the final dataset.                                                                                         |