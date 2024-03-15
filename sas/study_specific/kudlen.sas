/************************************************************************************
* Program/Macro:             kudlen.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Alex Khylko
* Date:                      20AUG2021
* Program Title:             
*
* Description:               Change variable length to the maximum length of value in it.
* Remarks:
* Input:                     &inds dataset
* Output:                    &outds dataset with variables length trimmed 
*
* Parameters:                inds - name of the input dataset.
* 							 outds - name of output dataset.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %kudlen(dm);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 1				Oleksii Mikryukov			   21JUL2022		   Fixed behaviour for empty dataset
* 																   Fixed behaviour when dataset has variables with "_" prefix
************************************************************************************/

%macro kudlen(inds /*Required. Name of the input dataset.*/,
			  outds=&inds. /*Default: input dataset. Name of output dataset.*/,
			  debug=N /*Default: N. If N then deletes temporary datasets.*/);

	%local end_kudlen i params_to_check param_name param_value charvars nwrd wrd lenvar reset lblset fmt;

	%*Flag for premature macro termination;
	%let end_kudlen = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds outds;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: kudlen.sas - &param_name. is required parameter and should not be NULL);
			%let end_kudlen = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_kudlen. = Y %then %goto endmac;

	data __tmp_&sysmacroname._1;
		set &inds.;
	run;

	%*Create a dataset with metadata.;
	proc contents data = __tmp_&sysmacroname._1 out = __tmp_&sysmacroname._2 noprint varnum;
	run;

	proc sort data = __tmp_&sysmacroname._2;
		by memname varnum;
	run;

	data __tmp_&sysmacroname._3;
		set __tmp_&sysmacroname._2;
		by memname varnum;
		length charvars $32767;
		retain charvars;

		%*Put all character variable names into a macro variable.;
		if type = 2 and length(charvars) <= 1 then charvars = strip(name);
		else if type = 2 then charvars = strip(charvars)||" "||strip(name);

		if last.memname then call symput("charvars", charvars);
	run;

	%*Count number of variables.;
	%let nwrd = %sysfunc(countw(&charvars.));

	data __tmp_&sysmacroname._4 (keep = len_:);
		set __tmp_&sysmacroname._1 end = last;

		%*Count length of each variable;
		%do i = 1 %to &nwrd.;
			%let wrd = %scan(&charvars., &i.);
			len_&wrd. = length(&wrd.);
		%end;
		
	run;

	%*Rename all variables in a dataset;
	%xurnm(__tmp_kudlen_4, mode = remove, rchar = 4, debug = &debug.);

	%*Find maximum length of each variable.;
	proc sql noprint;
		select catx(" ", "max(", name, ") as", name) into :max_list separated by ","
		from dictionary.columns
		where lowcase(libname) = "work" 
		and lowcase(memname) = lowcase("__tmp_&sysmacroname._4");

		create table __tmp_&sysmacroname._5 as 
			select &max_list.
			from __tmp_&sysmacroname._4;
	quit;

	proc transpose data = __tmp_&sysmacroname._5 out = __tmp_&sysmacroname._6 prefix = __tmp_len name = name ;
	run;

	proc sort data = __tmp_&sysmacroname._2;
		by name;
	run;

	proc sort data = __tmp_&sysmacroname._6;
		by name;
	run;

	%*Merge length back to the metadata.;
	data __tmp_&sysmacroname._7;
		merge __tmp_&sysmacroname._2 __tmp_&sysmacroname._6;
		by name;	
	run;

	proc sort data = __tmp_&sysmacroname._7;
		by memname varnum;
	run;

	data __tmp_&sysmacroname._8;
		set __tmp_&sysmacroname._7;
		by memname varnum;
		length lenvar reset lblset fmt $32767;
		retain lenvar reset lblset fmt;

		if missing(__tmp_len1) then call missing(__tmp_len1);
		if type = 2 and missing(__tmp_len1) then __tmp_len1 = 1;

		if _n_ = 1 then lenvar = "";
		if _n_ = 1 then reset = "";
		if _n_ = 1 then lblset = "";
		if _n_ = 1 then fmt = "";

		%*Create macro variables to apply length, label, format and rename them.;
		lenvar = strip(strip(lenvar)||" "||strip(name)||" "||ifc(type = 1, "8", "$"||strip(put(__tmp_len1, best.))));

		reset = strip(strip(reset)||" "||strip(name)||"=__tmp_kudlen_"||strip(name)||";");
		if not missing(label) then lblset = strip(strip(lblset)||" "||strip(name)||'= "'||strip(label)||'"');

		if not missing(format) then do;
			if formatl > 0 then format = strip(format)||strip(put(formatl, best.));
			fmt = strip(fmt)||" "||strip(strip(name)||" "||strip(format)||".");
		end;

		if last.memname then do;
			call symput("lenvar", lenvar);
			call symput("reset", reset);
			call symput("lblset", lblset);
			call symput("fmt", fmt);
		end;
	run;

	%*Rename all variables in a dataset;
	%xurnm(__tmp_kudlen_1, prefix=__tmp_kudlen_, debug = &debug.);

	%*Apply variables length, label, format and rename them.;
	data &outds. %if &debug. = N %then (drop = __tmp_kudlen:);;
		length &lenvar.;
		set __tmp_&sysmacroname._1;
		&reset.;
		label &lblset.;
		format &fmt.;;
	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets library = work nolist;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend kudlen;