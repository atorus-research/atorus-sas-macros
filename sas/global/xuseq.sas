/**
* @file xuseq.sas
* @brief Create --SEQ variable
*
* @author Atorus Research
* @date 14JUL2022
*
* @param[in] inds Name of the input dataset (Required)
* @param[in] sortvars Sort order for the dataset (Required)
* @param[in] prefix Prefix for the --SEQ variable name (Optional)
* @param[in] debug Flag that determines whether to delete temporary variables or not (Default: N)
*
* @return &inds dataset with --SEQ variable
*
* @par Example:
* @code
* %xuseq(dm, usubjid);
* %xuseq(adlb, usubjid paramcd adt adtm, prefix=a);
* @endcode
*
* @see N/A
*/

%macro xuseq(inds /*Required. Name of the input dataset.*/,
			 sortvars /*Required. Sort order for the dataset.*/,
			 prefix= /*Optional. Prefix for the --SEQ variable name.*/,
			 debug=N /*Default: N. If N then deletes temporary variables.*/);

	%local end_xuseq params_to_check i param_name param_value pref;

	%*Flag for premature macro termination;
	%let end_xuseq = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds sortvars;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xuseq.sas - &param_name. is required parameter and should not be NULL);
			%let end_xuseq = Y;
		%end;
	%end;

	%*Check if &domain. and &prefix. are empty then put log message;
	%if %symexist(domain) = 0 and &prefix. = %then %do;
		%put %str(ERR)%str(OR: xuseq.sas - prefix = %nrstr(&domain) by default, but %nrstr(&domain) is not resolved. Either resolve %nrstr(&domain) variable before macro call, or specify the value in prefix parameter);
		%let end_xuseq = Y;
	%end;
	%*Else if &prefix. is specified then use &prefix.;
	%else %if &prefix. ^= %then %do;
		%let pref = &prefix.;
	%end;
	%*Else if &prefix. is not specified and &domain. exists then use &domain.;
	%else %if %symexist(domain) = 1 %then %do;
		%let pref = &domain.;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xuseq. = Y %then %goto endmac;

	%*Sort the dataset by sorting order;
	proc sort data = &inds. out = &inds.;
		by &sortvars.;
	run;

	%*Create --SEQ variable;
	data &inds. %if &debug. = N %then %do; (drop = __tmp_n) %end;;
		set &inds.;
		by &sortvars.;

		%*Retain temporary variable __tmp_n;
		retain __tmp_n;

		%*Create sequence;
		if first.usubjid then __tmp_n = 1;
		else __tmp_n + 1;

		%*Copy values from __tmp_n to --SEQ variable;
		&pref.seq = __tmp_n;

	run;

	%endmac:

%mend xuseq;