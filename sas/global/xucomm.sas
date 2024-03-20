/************************************************************************************
* Program/Macro:             xucomm.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      15JUL2022
* Program Title:             
*
* Description:               Macro which creates CO domain records from the dataset.
* Remarks:
* Input:                     &inds input dataset
* Output:                    XX_comm dataset with comments
*
* Parameters:                inds - name of the input dataset.
*							 invar - name of the input variable to get comments from.
*							 idvar - name of the id variable.
*							 qc - flag to indicate if macro is used on QC side.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xucomm(dm, dmcomm);
*							 %xucomm(qclb, lbcomm, idvar=lbseq, qc=Y);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 
************************************************************************************/

%macro xucomm(inds /*Required. Name of the input dataset to get comments from.*/,
			  invar /*Required. Name of the input variable to get comment from.*/,
			  idvar= /*Optional. Name of the id variable.*/,
			  qc=N /*Default: N. Specify Y if macro is used on QC side.*/,
			  debug=N /*Default: N. If N then delete temporary datasets.*/);

	%local end_xucomm params_to_check i param_name param_value idv vtype nvars dscheck speccheck;

	%*Flag for premature macro termination;
	%let end_xucomm = N;

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
			%put %str(ERR)%str(OR: xucomm.sas - &param_name. is required parameter and should not be NULL);
			%let end_xucomm = Y;
		%end;
	%end;

	%*Check if &domain. is not resolved then put log message;
	%if %symexist(domain) = 0 %then %do;
		%put %str(ERR)%str(OR: xucomm.sas - please resolve variable %nrstr(&domain) with domain name (example: DM) before macro call);
		%let end_xucomm = Y;
	%end;
	%else %if &idvar. ^= %then %do;
		%*If &domain. = dm and idvar is specified then put log message;
		%if %lowcase(&domain.) = dm %then %do;
			%put %str(WAR)%str(NING: xucomm.sas - idvar parameter is ignored if %nrstr(&domain) = DM. Please leave idvar empty to suppress that message);
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
	%if &end_xucomm. = Y %then %goto endmac;

	%*Get metadata for CO;
	%xtmeta(CO, qc=&qc., debug=&debug.);

	%xtorder(CO, debug=&debug.);

	%xusplit(&inds., &invar., outds=__tmp_xucomm_0, prefix=__comm, debug=&debug.)

	data __tmp_&sysmacroname._1;
		set EMPTY_CO
			__tmp_&sysmacroname._0(rename = (domain = __tmp_domain &invar. = __comm) where = (not missing(__comm)));
	run;

	%*Determine how many COVALx variables should be created;
	proc sql noprint;	
		select strip(put(count(*), best.)) into: nvars from sashelp.vcolumn
		where lowcase(libname) = "work" and lowcase(memname) = lowcase("__tmp_&sysmacroname._1") and index(lowcase(name), "__comm");
	quit;

	%*Determine the type of the input variable (char/num);
	%if &idv. ^= %then %do;
		data _null_;
			set __tmp_&sysmacroname._1;

			call symputx("vtype", vtype(&idv.));
		run;
	%end;

	data __tmp_&sysmacroname._2;
		set __tmp_&sysmacroname._1;
	
		domain = "CO";
		if not missing(__tmp_domain) then rdomain = strip(__tmp_domain);

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

		array __tmp_cols [*] $ __comm %if &nvars. > 1 %then %do; __comm1-__comm%eval(&nvars. - 1) %end;;
		array __tmp_coval [*] $ coval %if &nvars. > 1 %then %do; coval1-coval%eval(&nvars. - 1) %end;;

		do i = 1 to &nvars.;
			__tmp_coval[i] = strip(__tmp_cols[i]);
		end;
	run;

	%*Check to determine if any of COVALx is in dataset but not in spec;
	proc sql noprint;
		select upcase(name) into: dscheck separated by " " from sashelp.vcolumn
		where lowcase(libname) = "work" and lowcase(memname) = lowcase("__tmp_&sysmacroname._2") and index(lowcase(name), "coval") order by name;

		select upcase(name) into: speccheck separated by " " from sashelp.vcolumn
		where lowcase(libname) = "work" and lowcase(memname) = lowcase("EMPTY_CO") and index(lowcase(name), "coval") order by name;
	quit;

	%*Create a log message if any COVALx is not in spec;
	%if %length(&dscheck.) > %length(&speccheck.) %then %do;
		%let confvars = %substr(&dscheck.,%length(&speccheck.) + 1);

		%put %str(WAR)%str(NING: xucomm.sas - spec contains less COVALx variables than created dataset. Please add &confvars. to spec);
	%end;

	proc sort data = __tmp_&sysmacroname._2 nodupkey;
		by studyid rdomain usubjid idvar idvarval;
	run;

	%*Compute COSEQ;
	data __tmp_&sysmacroname._3;
		set __tmp_&sysmacroname._2;
		by studyid rdomain usubjid idvar idvarval;
		
		retain __tmp_seq 0;

		if first.usubjid then __tmp_seq = 1;
		else __tmp_seq + 1;

		coseq = __tmp_seq;
	run;

	%*Create intermediate XX_comm dataset for QC purposes;
	proc sort data = __tmp_&sysmacroname._3(keep = &cokeepstring.) %if &qc. = N %then %do; out = sdtm.&domain._comm; %end;
											    				   %else %do; out = qc&domain._comm; %end;
		by &cosortstring.;
	run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.: EMPTY_CO;
		run;
	%end;

	%endmac:

%mend xucomm;