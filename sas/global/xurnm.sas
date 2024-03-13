/************************************************************************************
* Program/Macro:             xurnm.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksii Mikryukov
* Date:                      14JUL2022
* Program Title:             
*
* Description:               Macro which renames all variables in the dataset.
* Remarks:
* Input:                     &inds input dataset
* Output:                    &outds dataset with all variables renamed
*
* Parameters:                inds - name of the input dataset.
*							 mode - (add/remove). Choose whether it add prefix or remove some characters.
*							 prefix - characters to add before variable name.
*							 rchar - number of characters to remove from the beginning of variable name.
*                            debug - flag, that determines whether to delete temporary datasets or not.
*
* Sample Call:               %xurnm(ds, mode = add, prefix = _);
* 							 %xurnm(ds, mode = remove, rchar = 2);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 1				Oleksii Mikryukov			   20Dec2022		   Fixed renaming bug, when variable name 
*																   has spaces or characters other than 
* 																   (A-Z, a-z, 0-9) or the underscore
************************************************************************************/

%macro xurnm(inds /*Required. Name of the input dataset.*/,
			 mode=add /*Default: add. Working mode (add/remove).*/,
			 prefix=_ /*Default: _. Characters to add before the variable name.*/,
			 rchar=1 /*Default: 1. Number of characters to remove from the beginning of the variable name.*/,
			 outds=&inds. /*Default: input dataset. Name of output dataset.*/,
			 debug=N /*Default: N. If N then deletes temporary datasets.*/);

	%local end_xurnm params_to_check i param_name param_value rename_list;

	%*Flag for premature macro termination;
	%let end_xurnm = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds mode outds;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xurnm.sas - &param_name. is required parameter and should not be NULL);
			%let end_xurnm = Y;
		%end;
		%else %do; 
			%*Check whether filename parameter has expected values;
			%if %lowcase(&param_name.) = mode %then %do;
				%if %lowcase(&param_value.) ^= add and %lowcase(&param_value.) ^= remove %then %do;
					%put %str(ERR)%str(OR: xurnm.sas - parameter &param_name. should be add or remove);
					%let end_xurnm = Y;
				%end;
				%*Parameter prefix is conditionally required, if mode=add;
				%if %lowcase(&param_value.) = add and &prefix. = %then %do;
					%put %str(ERR)%str(OR: xurnm.sas - parameter prefix should not be empty if mode = add);
					%let end_xurnm = Y;
				%end;
				%*Parameter rchar is conditionally required, if mode=remove;
				%if %lowcase(&param_value.) = remove and &rchar. = %then %do;
					%put %str(ERR)%str(OR: xurnm.sas - parameter rchar should not be empty if mode = remove);
					%let end_xurnm = Y;
				%end;
			%end;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xurnm. = Y %then %goto endmac;

	%*Create a dataset with dataset metadata.;
	proc contents data = &inds. out = __tmp_&inds._1 noprint varnum;
	run;

	%*Sort the dataset.;
	proc sort data = __tmp_&inds._1;
		by memname varnum;
	run;

	%*Create a macro variable, with list of renames.;
	data __tmp_&inds._2;
		set __tmp_&inds._1;
		by memname varnum;

		length new_name $8000;
		retain new_name;

		%*Add prefix to each variable in the dataset.;
		%if %lowcase(&mode.) = add %then %do;
			%*Use validvarname = any syntax below, i.e. 'var1'n = 'var2'n, so variables with dashes or other special characters renamed properly;
			if first.memname then new_name = "'"||strip(name)||"'n"||"="||"'&prefix."||strip(name)||"'n";
			else new_name = strip(new_name)||" "||"'"||strip(name)||"'n"||"="||"'&prefix."||strip(name)||"'n";

			if last.memname then call symput("rename_list", new_name);
		%end;
		%*Remove specified number of characters from the beginning of each variable name.;
		%if %lowcase(&mode.) = remove %then %do;
			if first.memname then new_name = strip(name)||"="||substr(strip(name), %eval(&rchar. + 1));
			else new_name = strip(new_name)||" "||strip(name)||"="||substr(strip(name), %eval(&rchar. + 1));

			if last.memname then call symput("rename_list", new_name);
		%end;

	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails library = work;
			delete __tmp_&inds.:;
		run;
	%end;

	%*Rename variables.;
	data &outds.;
		set &inds.(rename = (&rename_list.));
	run;

	%endmac:

%mend xurnm;