/************************************************************************************
* Program/Macro:             xusplit.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      15JUL2022
* Program Title:             
*
* Description:               Macro which splits long text variable into multiple shorter sub-variables.
* Remarks:
* Input:                     &inds input dataset
* Output:                    &outds with &prefix.-&prefix.X variables
*
* Parameters:                inds - name of the input dataset.
*							 invar - name of the input variable to split.
*							 outds - name of the output dataset.
*							 prefix - prefix for the output variables names.
*							 len - length of the output variables.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xusplit(cm, cmdecod);
*							 %xusplit(dv1, temn, outds=dv, prefix=dvterm)
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 
************************************************************************************/

%macro xusplit(inds /*Required. Name of the input dataset.*/,
			   invar /*Required. Name of the input variable to split.*/,
			   outds=&inds. /*Default: &outds. Name of the output dataset.*/,
			   prefix=&invar. /*Default: &invar. Prefix for the output variables names.*/,
			   len=200 /*Default: 200. Length of the output variables.*/,
			   debug=N /*Default: N. If N then delete temporary datasets.*/);

	%local end_xusplit params_to_check i param_name param_value nvars;

	%*Flag for premature macro termination;
	%let end_xusplit = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds invar outds prefix len;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xusplit.sas - &param_name. is required parameter and should not be NULL);
			%let end_xusplit = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xusplit. = Y %then %goto endmac;

	%*Create temporary order variable;
	data __tmp_&sysmacroname._1;
		set &inds.;

		__tmp_ord = _n_;
	run;

	%*If text length is more than &len. then split it to sub-variables with meaningful text less than &len.;
	data __tmp_&sysmacroname._2;
		set __tmp_&sysmacroname._1(where = (not missing(&invar.)));
		length __tmp_word __tmp_nystr $1000;

		&invar. = compbl(strip(&invar.));

		do i = 1 to countw(&invar., " ");
			__tmp_word = scan(&invar., i, " ");
			if length(__tmp_nystr) + length(__tmp_word) + 1 > &len. then do;
				output;
				__tmp_nystr = __tmp_word;
			end;
			else __tmp_nystr = catx(" ", __tmp_nystr, scan(&invar., i, " "));
		end;
		if __tmp_nystr ^= "" then output;
	run;

	proc sort data = __tmp_&sysmacroname._2;
		by __tmp_ord;
	run;

	proc transpose data = __tmp_&sysmacroname._2 out = __tmp_&sysmacroname._3 prefix = __tmp_c;
		by __tmp_ord;
		var __tmp_nystr;
	run;

	%*Determine how many sub-variables should be created;
	proc sql noprint;	
		select strip(put(count(*), best.)) into: nvars from sashelp.vcolumn
		where lowcase(libname) = "work" and lowcase(memname) = lowcase("__tmp_&sysmacroname._3") and index(lowcase(name), "__tmp_c");
	quit;

	data __tmp_&sysmacroname._4(keep = __tmp_ord &invar. %if &nvars. > 1 %then %do; &prefix.: %end; );
		set __tmp_&sysmacroname._3;

		array __tmp_cols [*] $ __tmp_c1-__tmp_c&nvars.;
		array __tmp_&prefix. [*] $&len. &invar. %if &nvars. > 1 %then %do; &prefix.1-&prefix.%eval(&nvars. - 1) %end;;

		do i = 1 to &nvars.;
			__tmp_&prefix.[i] = strip(__tmp_cols[i]);
		end;
	run;

	%*Set the length of the input variable same as length defined in &len.;
	proc sql;
		alter table __tmp_&sysmacroname._1 modify &invar. character(&len.);
	quit;

	data &outds. %if &debug. = N %then %do; (drop = __tmp_:) %end;;
		merge __tmp_&sysmacroname._1(in = a) __tmp_&sysmacroname._4;
		by __tmp_ord;
		if a;
	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xusplit;