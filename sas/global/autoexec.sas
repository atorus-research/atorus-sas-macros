/**
* @file autoexec.sas
* @brief Macro to be placed before each program execution
* @details Sets defaults based on operating system.
*
* @author Atorus Research
* @date 19FEB2021
*
* @remarks For current process autoexec should be put into same folder as sas.exe
*          and it will automatically be pulled in.
*
* @see N/A
*/

%macro init;

	%*This option allows using macro "in" operator.;
	options minoperator mindelimiter=",";

	%*Variables declaration;
	%global __root II __sponsor_level __prod_qc_separation;
	%*Root folder path.;
	%let __root = ;
	%*Left or right slash depends on OS type.;
	%let II = ;
	%*Defines if a client level folders should exist. Should be Y or N.;
	%let __sponsor_level = Y;
	%*Tells if there is an extra level under development/final area segregating prod vs QC. Should be Y or N.;
	%let __prod_qc_separation = Y; 

	%*Based on the OS type assign root path and a "slash" - left or right.;
	%*Put error to the log if OS type was not described here.;
	%if &sysscp=WIN %then %do;
		%let __root = F:\projects;
		%let II = \;
	%end;
	%else %if &sysscp in (SUN 4, SUN 64, LIN X64) %then %do;
		%let __root = /sambaShare/projects;
		%let II = /;
	%end;
	%else %do;
		%put ERROR: autoexec.sas - operating system &sysscp in not defined.;
	%end;

%mend init;

*Call the macro.;
%init;

*Setup path to global macros library.;
options mautosource sasautos=("&__root.&II.utils&II.func", sasautos) validvarname=any;
