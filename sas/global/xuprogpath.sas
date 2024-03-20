/************************************************************************************
* Program/Macro:             xuprogpath.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      19FEB2021
* Program Title:             
*
* Description:               Find out full path to currently executing file. Create task-related
*                            global variables, assuming the file is a program, being executed within
*                            Atorus standard programming environment.
* Remarks:                   This macro should be called automatically within %xumprint macro and setup.sas.
* Input:                     N/A
* Output:   				 N/A
* 
* Parameters:                N/A
*                            
* Sample Call:               %xuprogpath;
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xuprogpath;

	%if %symexist(_sasprogramfile) %then %do;
		%if %length(%sysfunc(compress(&_sasprogramfile., "'"))) ^= 0 %then %do;
			%global __program_full_path __clnt __comp __prot __subfolders __task __level __side __type __p_name __p_path __log_path __lst_path;
			%local projects_path;

			%*When the program is run withing SAS EG this global variable exists to tell us the full path.;
			%let __program_full_path = %sysfunc(compress(&_sasprogramfile., "'"));

			%*This is the path without leading projects root (which is specified in the autoexec.sas). The rest can be easily sliced for task information.;
			%let projects_path = %substr(&__program_full_path., %eval(%sysfunc(find(&__program_full_path., &__root.)) + %length(&__root.) + 1));

			%*Task information;
			%*Assign top-level directory information depending on the value of "__sponsor_level" variable. This variable is declared in the autoexec.sas and is constant to entire SCE.;
			%*Assign folder names.;
			%if &__sponsor_level. = Y %then %do;
				%let __clnt = %scan(&projects_path., 1, &II.);
				%let __comp = %scan(&projects_path., 2, &II.);
				%let __prot = %scan(&projects_path., 3, &II.);
			%end;
			%else %do;
				%let __clnt = ;
				%let __comp = %scan(&projects_path., 1, &II.);
				%let __prot = %scan(&projects_path., 2, &II.);
			%end;

			%*No matter where the program is situated ("development" or "final" area) the previous item of the "projects_path" list is the project task name.;
			%if %sysfunc(find(&projects_path., final)) %then %do;
				%let __task = %sysfunc(reverse(%scan(%substr(%sysfunc(reverse(&projects_path.)), %sysfunc(find(%sysfunc(reverse(&projects_path.)), %sysfunc(reverse(final))))), 2, &II.)));
			%end;
			%if %sysfunc(find(&projects_path., development)) %then %do;
				%let __task = %sysfunc(reverse(%scan(%substr(%sysfunc(reverse(&projects_path.)), %sysfunc(find(%sysfunc(reverse(&projects_path.)), %sysfunc(reverse(development))))), 2, &II.)));
			%end;

			%*Probably the easiest way to assign "level": final or development.;
			%if %sysfunc(find(&projects_path., development)) %then %do;
				%let __level = development;
			%end;
			%if %sysfunc(find(&projects_path., final)) %then %do;
				%let __level = final;
			%end;

			%*Dig into finding list of subfolders only when there is a "distance" between protocol name and task name.;
			%if %eval(%sysfunc(find(&projects_path., &__task.&II.&__level.)) - %eval(%sysfunc(find(&projects_path., &__prot.)) + %length(&__prot.) + 1) - 1) > 0 %then %do;
				%let __subfolders = %substr(&projects_path., %eval(%sysfunc(find(&projects_path., &__prot.)) + %length(&__prot.) + 1), %eval(%sysfunc(find(&projects_path., &__task.&II.&__level.)) - %eval(%sysfunc(find(&projects_path., &__prot.)) + %length(&__prot.) + 1) - 1)); 
			%end;
			%else %do;
				%let __subfolders = ; 
			%end;

			%*Prod or val.;
			%if &__prod_qc_separation. = Y %then %do;
				%let __side = %scan(&projects_path., %eval(%sysfunc(count(%substr(&projects_path., 1, %sysfunc(find(&projects_path., &__level.))), &II.)) + 2), &II.);
			%end;
			%else %do;
				%let __side = ;
			%end;

		    %*Sdtm, adam, tlf.;
		    %let __type = %scan(&projects_path., -2, &II.);

			%*Program name and path.;
			%let __p_name = %qscan(%qscan(&__program_full_path., -1, &II.), -2, .);
		    %let __p_path = %substr(&__program_full_path., 1, %eval(%length(&__program_full_path.) - %length(&__p_name..sas) - 1));

		    %*Logs and LST path.;
			%let __log_path = %sysfunc(tranwrd(&__p_path.,program,log));
			%let __lst_path = %sysfunc(tranwrd(&__p_path.,program,lst));

			%*Display all macro variables in log.;
			%put ******************************************************************************************************;
		    %put === Program being executed === ;
			%put Program executed by: %sysfunc(compress(&_clientuserid., "'"));
			%put Program full path  : &__program_full_path.;
		    %put Program name       : &__p_name.;
		    %put Program path       : &__p_path.;
		    %put ******************************************************************************************************;
		    %put === Task Information === ;
			%put Client    : &__clnt.;
			%put Compound  : &__comp.;
			%put Protocol  : &__prot.;
			%put Subfolders: &__subfolders.;
			%put Task      : &__task.;
			%put Level     : &__level.;
			%put Side      : &__side.;
		    %put Type      : &__type.;
			%put ******************************************************************************************************;
		    %put === Logs and lst outputs path === ;
			%put Log path: &__log_path.;
		    %put Lst path: &__lst_path.;
			%put ******************************************************************************************************;
		%end;
	%end;

%mend xuprogpath;