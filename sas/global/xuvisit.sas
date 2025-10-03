/**
* @file xuvisit.sas
* @brief Derive VISIT/VISITNUM variables using TV and SV domains
*
* @author Atorus Research
* @date 19JUL2022
*
* @param[in] inds Name of the input dataset (Required)
* @param[in] dtcdate Name of the date variable (Required)
* @param[in] outds Name of the output dataset (Default: &inds)
* @param[in] debug Flag that determines whether to delete temporary datasets or not (Default: N)
*
* @return &outds dataset with VISIT/VISITNUM variables
*
* @par Example:
* @code
* %xuvisit(vs,vsdtc);
* @endcode
*
* @see N/A
*/

%macro xuvisit(inds /*Required. Name of the input dataset.*/,
			   dtcdate /*Required. Name of the date variable.*/,
			   outds=&inds. /*Default: &inds. Name of the output dataset.*/,
			   debug=N /*Default: N. If N then deletes temporary datasets.*/);

	%local end_xuvisit params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_xuvisit = N;

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
			%put %str(ERR)%str(OR: xuvisit.sas - &param_name. is required parameter and should not be NULL);
			%let end_xuvisit = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xuvisit. = Y %then %goto endmac;

	%*Upload SV and TV domain;
	%xuload(sv tv, sdtm);

	proc sort data = tv nodupkey;
		by visit;
	run;

	proc sort data = &inds. out = __tmp_&sysmacroname._1;
		by visit;
	run;

	%*Upload the dataset and create VISITNUM variable.;
	data __tmp_&sysmacroname._2;
		merge __tmp_&sysmacroname._1(in = a) tv(keep = visit visitnum rename=(visitnum = __tmp_visitnum_tv));
		by visit;
		if a;
		
		visitnum = __tmp_visitnum_tv;

		%*For unscheduled visits, VISIT and VISITNUM are created based on date;
		if index(lowcase(visit), "uns") > 0 then do;
			svstdtc = substr(&dtcdate., 1, 10);
		end;
	run;

	%*Subset unscheduled visits;
	proc sort data = sv out = __tmp_&sysmacroname._3(keep = usubjid svstdtc visit visitnum rename = (visit = __tmp_visit_sv visitnum = __tmp_visitnum_sv) where = (index(lowcase(__tmp_visit_sv), "uns") > 0));
		by usubjid svstdtc;
	run;

	proc sort data = __tmp_&sysmacroname._2;
		by usubjid svstdtc;
	run;

	%*Create VISIT and VISITNUM for unscheduled visits;
	data &outds.(drop = __tmp_: svstdtc);
		merge __tmp_&sysmacroname._2(in = a) __tmp_&sysmacroname._3;
		by usubjid svstdtc;
		if a;

		if not missing(svstdtc) then do;
			visitnum = __tmp_visitnum_sv;
			visit = __tmp_visit_sv;
		end;
	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails library = work;
			delete __tmp_&sysmacroname.:;
		quit;
	%end;

	%endmac:

%mend xuvisit;