/************************************************************************************
* Program/Macro:             xusupp.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      18JUL2022
* Program Title:             
*
* Description:               Macro which creates and adds variables to SUPP-- domain.
* Remarks:
* Input:                     &inds input dataset
* Output:                    SUPPXX dataset
*
* Parameters:                inds - name of the input dataset.
*							 invar - name of the variable to add to SUPP-- domain.
*							 idvar - name of the id variable.
*							 qlabel - text to be displayed in QLABEL variable.
*							 qorig - text to be displayed in QORIG variable.
*							 qeval - text to be displayed in QEVAL variable.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xusupp(dm, RACEOTH, qlabel=%str(Race, Other), qorig=CRF, qeval=, debug=N);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 
************************************************************************************/

%macro xusupp(inds /*Required. Name of the input dataset.*/,
			  invar /*Required. Name of the variable to add to --SUPP domain.*/,
			  idvar= /*Optional. Name of the id variable.*/,
			  qlabel= /*Optional. Text to be displayed in QLABEL variable.*/,
			  qorig= /*Optional. Text to be displayed in QORIG variable.*/, 
			  qeval= /*Optional. Text to be displayed in QEVAL variable.*/,
			  debug=N /*Default: N. If N then deletes temporary datasets.*/);

	%local end_xusupp params_to_check i param_name param_value idv vtype labchk;

	%*Flag for premature macro termination;
	%let end_xusupp = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds invar;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xusupp.sas - &param_name. is required parameter and should not be NULL);
			%let end_xusupp = Y;
		%end;
	%end;

	%*Check if &domain. is not resolved then put log message;
	%if %symexist(domain) = 0 %then %do;
		%put %str(ERR)%str(OR: xusupp.sas - please resolve variable %nrstr(&domain) with domain name (example: DM) before macro call);
		%let end_xusupp = Y;
	%end;
	%else %if &idvar. ^= %then %do;
		%*If &domain. = dm and idvar is specified then put log message;
		%if %lowcase(&domain.) = dm %then %do;
			%put %str(WAR)%str(NING: xusupp.sas - idvar parameter is ignored if %nrstr(&domain) = DM. Please leave idvar empty to suppress that message);
			%let idv = ;
		%end;
		%*Else if &domain. ^= dm and idvar is specified then use idvar;
		%else %do;
			%let idv = &idvar.;
		%end;
	%end;
	%else %do;
		%*If &domain. = dm then idvar should be empty;
		%if %lowcase(&domain.) = dm %then %do;
			%let idv = ;
		%end;
		%*Else use &domain.seq;
		%else %do;
			%let idv = &domain.seq;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xusupp. = Y %then %goto endmac;

	%*Sort the dataset;
	proc sort data = &inds. out = __tmp_&sysmacroname._1;
		by studyid domain usubjid &idv.;
	run;

	%*Transpose the dataset;
	proc transpose data = __tmp_&sysmacroname._1(keep = studyid domain usubjid &idv. &invar.) out = __tmp_&sysmacroname._2;
		by studyid domain usubjid &idv.;
		var &invar.;
	run;

	%*Determine the type of the input variable (char/num);
	%if &idv. ^= %then %do;
		data _null_;
			set __tmp_&sysmacroname._2;

			call symputx("vtype", vtype(&idv.));
		run;
	%end;

	%*Check if _label_ exists;
	data _null_;
		dset = open("__tmp_&sysmacroname._2");
		call symputx("labchk", varnum(dset, "_LABEL_"));
	run;

	%*Create SUPP-- domain;
	data __tmp_&sysmacroname._3(drop = domain _: col1 &idv.);
		set EMPTY_SUPP&domain.
			__tmp_&sysmacroname._2(where = (not missing(col1)));

			if not missing(domain) then rdomain = strip(domain);

			%*If &idv. is not empty then create IDVAR/IDVARVAL based on the type of &idv.;
			%if &idv. ^= %then %do;
				idvar = "%upcase(&idv.)";
				%if &vtype. = N %then %do;
					idvarval = strip(put(&idv., best.));
				%end;
				%if &vtype. = C %then %do;
					idvarval = strip(&idv.);
				%end;
			%end;

			if not missing(_name_) then qnam = upcase(strip(_name_));

			%*If qlabel parameter specified, then use that value for QLABEL variable;
			%if &qlabel. ^= %then %do;
				qlabel = "&qlabel.";
			%end;
			%*Else if variable _label_ exists, then use it;
			%else %if &labchk. > 0 %then %do;
				if not missing(_label_) then qlabel = strip(_label_);
			%end;
			%*Else create a log message;
			%else %do;
				%put %str(WAR)%str(NING: xusupp.sas - QLABEL is set to NULL. Either assign a label for %upcase(&invar.) or specify label in qlabel parameter);
			%end;

			if not missing(col1) then qval = strip(col1);
			qorig = "&qorig.";
			qeval = "&qeval.";
	run;

	%*Append records to SUPP--, in case of multiple calls;
	proc append base = supp&domain. data = __tmp_&sysmacroname._3 force;
	run;

	%*Sort SUPP--;
	proc sort data = supp&domain. nodupkey;
		by _all_;
	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails library = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xusupp;