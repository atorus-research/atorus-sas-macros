/************************************************************************************
* Program/Macro:             setup.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Rostyslav Didenko
* Date:                      18FEB2021
* Program Title:             
*
* Description:               Setups global variables __root, __clnt_I, __comp, __prot, __subfolders_I,
*							 __task, __level, __side_I using %xuprogpath macro. Creates libraries.
* Remarks:                   This macro should be called automatically within %xumprint macro.
* Input:                     N/A
* Output:  					 N/A
* 
* Parameters:                N/A
*                            
* Sample Call:               N/A
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%*Get program execution path and setup task/client related global macro variables.;
%xuprogpath;

%*Create __clnt_I, __subfolders_I, __side_I variables based on directory structure.;
%macro cond_setup;

	%global __clnt_I __subfolders_I __side_I;

	%*If __clnt global variable from %xuprogpath is not null then __clnt_I is set to "/[client folder name]";
	%if &__clnt ^= %then %do;
		%let __clnt_I = &II.&__clnt;
	%end;
	%*If __clnt global variable from %xuprogpath is null then __clnt_I is set to null;
	%else %do;
		%let __clnt_I = ;
	%end;

	%*If __subfolders global variable from %xuprogpath is not null then __subfolders_I is set to "/[list of subfolder names]";
	%if &__subfolders ^= %then %do;
		%let __subfolders_I = &II.&__subfolders;
	%end;
	%*If __subfolders global variable from %xuprogpath is null then __subfolders_I is set to null;
	%else %do;
		%let __subfolders_I = ;
	%end;

	%*If __side global variable from %xuprogpath is not null then __side_I is set to "/[side folder name]";
	%if &__side ^= %then %do;
		%let __side_I = &II.&__side;
	%end;
	%*If __side global variable from %xuprogpath is null then __side_I is set to null;
	%else %do;
		%let __side_I = ;
	%end;

%mend cond_setup;

%cond_setup;

%*Set libraries.;
%macro set_lib;

	libname specs "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs";
	libname crf "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.raw&II.crf";
	libname external "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.raw&II.external";
	libname dict "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.raw&II.dict";
	libname rawmisc "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.raw&II.misc";
	libname raw (crf, external, dict, rawmisc);

	%*For direcrory that has prod/val separation.;
	%if &__side ^= %then %do;
		libname sdtm "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.prod&II.sdtm";
		libname adam "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.prod&II.adam";
		libname tfl "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.prod&II.tfl";
		libname misc "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.prod&II.misc";

		libname vsdtm "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.val&II.sdtm";
		libname vadam "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.val&II.adam";
		libname vtfl "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.val&II.tfl";
		libname vmisc "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.val&II.misc";
	%end;
	
	%*For direcrory that has not prod/val separation.;
	%else %do;
		libname sdtm "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.sdtm";
		libname adam "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.adam";
		libname tfl "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.tfl";
		libname misc "&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&II.misc";
	%end;

%mend set_lib;

%set_lib;

%*Setup path to global and task-specific macros library.;
options mautosource sasautos=("&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&__side_I.&II.func",
							  "&__root.&II.utils&II.func",
                              sasautos);