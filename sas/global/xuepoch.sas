/************************************************************************************
* Program/Macro:    		 xuepoch.sas
* Protocol:         
* SAS Ver:          		 SAS 9.4 V9
* Author:           		 Oleksandr Homel
* Date:             		 20JUL2022
* Program Title:    
*
* Description:      		 Macro to derive EPOCH variable using SE SDTM dataset
* Remarks:
* Input:            		 SE dataset from SDTM library, &inds dataset
* Output:           		 &outds dataset
*
* Parameters:       		 inds - name of the input dataset.
*							 dtcdate - name of the date variable.
*							 outds - name of the output dataset.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                   
* Sample Call:      		 %xuepoch(lb, lbdtc);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xuepoch(inds /*Required. Name of the input dataset.*/, 
			   dtcdate /*Required. Name of the date variable.*/,
			   outds=&inds. /*Default: &inds. Name of the output dataset.*/,
			   debug=N /*Default: N. If N then deletes temporary variables.*/);

	%local end_xuepoch params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_xuepoch = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds dtcdate outds;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xuepoch.sas - &param_name. is required parameter and should not be NULL);
			%let end_xuepoch = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xuepoch. = Y %then %goto endmac;

	%*Upload SE domain;
	%xuload(se, sdtm);

	proc sort data = se out = __tmp_&sysmacroname._1;
		by usubjid sestdtc;
	run;

	%*Transpose SE to get one record per subject dataset;
	proc transpose data = __tmp_&sysmacroname._1 out = __tmp_&sysmacroname._2 prefix = tm_st_;
		by usubjid;
		var sestdtc;
		id epoch;
	run;

	proc sort data = &inds. out = __tmp_&sysmacroname._3;
		by usubjid;
	run;

	%*Merge input dataset and transposed SE domain;
	data &outds. %if &debug. = N %then %do; (drop = tm_st_: __tmp_: _name_ _label_) %end;;
		merge __tmp_&sysmacroname._3(in = a) __tmp_&sysmacroname._2;
		by usubjid;
		if a;

		array __tmp_st [*] $ tm_st_:;

		%*Derive EPOCH for each record;
		do __tmp_i = 1 to dim(__tmp_st);
			%*Get the minimum length among two dates;
			__tmp_length = min(length(__tmp_st[__tmp_i]), length(&dtcdate.));

			%*If both dates have time then compare them without truncation;
			if __tmp_length = 16 then do;
				if __tmp_st[__tmp_i] <= &dtcdate. then epoch = substr(vname(__tmp_st[__tmp_i]), 7);
			end;
			%*If at least one date has no time, then compare only date parts;
			else if __tmp_length = 10 then do;
				if substr(__tmp_st[__tmp_i], 1, __tmp_length) <= substr(&dtcdate., 1, __tmp_length) then epoch = substr(vname(__tmp_st[__tmp_i]), 7);
			end;
			%*If at least one date is partial, then compare by the length of that date;
			else if cmiss(__tmp_st[__tmp_i], &dtcdate.) = 0 then do;
				if substr(__tmp_st[__tmp_i], 1, __tmp_length) <= substr(&dtcdate., 1, __tmp_length) then epoch = substr(vname(__tmp_st[__tmp_i]), 7);
			end;
		end;
	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xuepoch;