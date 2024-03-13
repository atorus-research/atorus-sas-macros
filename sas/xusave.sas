/************************************************************************************
* Program/Macro:             xusave.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksandr Homel
* Date:                      13JUL2022
* Program Title:             
*
* Description:               Macro which keeps needed varibales, applies sorting order,
*					  		 applies dataset label and saves .sas7bdat and .xpt files permanently.
* Remarks:
* Input:                     &inds dataset
* Output:                    &outds dataset in &outlib library
*
* Parameters:                inds - name of the input dataset.
*							 outlib - name of the output library.
*	 						 outds - name of the output dataset.
*							 keepvars - list of variables to keep.
*							 sortvars - sort order for the dataset.
*							 dslbl - label for the dataset.
*							 xpt - flag, that determines whether to save .xpt file or not.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xusave(dm, sdtm, outds=dm, keepvars=studyid usubjid ..., sortvars=usubjid, dslbl=Demographics, xpt=Y);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xusave(inds /*Required. Name of the input dataset.*/,
			  outlib /*Required. Name of the output library.*/,
			  outds=&inds. /*Default: &inds. Name of the output dataset.*/,
			  keepvars= /*Optional. List of variables to keep.*/,
			  sortvars= /*Optional. Sort order for the dataset.*/,
			  dslbl= /*Optional. Label for the dataset.*/,
			  xpt=Y /*Default: Y. If Y then saves .xpt file.*/,
			  debug=N /*Default: N. If N then delete temporary datasets.*/);

	%local end_xusave params_to_check i param_name param_value xportlib;

	%*Flag for premature macro termination;
	%let end_xusave = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds outlib outds;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xusave.sas - &param_name. is required parameter and should not be NULL);
			%let end_xusave = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xusave. = Y %then %goto endmac;

	%*Create intermediate dataset;
	data __tmp_&sysmacroname._&inds.;
		set &inds.;
	run;

	%*Sort the dataset, if sort order is specified;
	%if &sortvars. ^= %then %do;
		proc sort data = __tmp_&sysmacroname._&inds.;
			by &sortvars.;
		run;
	%end;

	%*Save .sas7bdat file, keep needed variables, apply dataset label;
	data &outlib..&outds. (%if &dslbl. ^= %then %do; label = "&dslbl." %end;
						   %if &keepvars. ^= %then %do; keep = &keepvars. %end;); 
		set __tmp_&sysmacroname._&inds.;
		%if &sortvars. ^= %then %do; by &sortvars.; %end;
	run;

	%*Save .xpt file;
	%if &xpt. = Y %then %do;
		%let xportlib = %sysfunc(pathname(&outlib.));
		libname xptfile xport "&xportlib.&II.%sysfunc(lowcase(&outds.)).xpt";

		data xptfile.&outds. (%if &dslbl. ^= %then %do; label = "&dslbl." %end;
							  %if &keepvars. ^= %then %do; keep = &keepvars. %end;);
			set __tmp_&sysmacroname._&inds.;
			%if &sortvars. ^= %then %do; by &sortvars.; %end;
		run;
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
	    proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xusave;