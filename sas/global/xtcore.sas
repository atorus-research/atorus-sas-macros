/************************************************************************************
* Program/Macro:             xtcore.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      14JUL2022
* Program Title:             
*
* Description:               Adds ADSL core variables to an analysis dataset.
* Remarks:
* Input:                     &inds parent dataset, metadata spreadsheet, ADSL dataset
* Output:                    &inds with ADSL core variables added to the end of the dataset, global macro variable &core_vars
*
* Parameters:                inds - name of the parent dataset.
*							 outds - name of the output dataset.
* 							 filename - indicates source file to use: SDTM_spec_Codelist.csv or ADaM_spec_Codelist.csv.
* 							 filepath - indicates path to source file.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*
* Sample Call:               %xtcore(adlb);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 
************************************************************************************/

%macro xtcore(inds /*Required. Name of the parent dataset for adding ADSL core variables.*/,
			  outds=&inds. /*Default: &inds. Name of the output dataset.*/,
			  filename=ADAM_spec_Variables.csv /*Default: ADaM_spec_Codelist.csv. Indicates source file name.*/,
			  filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs /*Default: final/specs. Indicates path to source file.*/,
			  debug=N /*Default: N. If Y then deletes temporary datasets.*/);

    %global core_vars;
	%local end_xtcore params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_xtcore = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds outds filename filepath;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xtcore.sas - &param_name. is required parameter and should not be NULL);
			%let end_xtcore = Y;
		%end;
	%end;

	%*Check whether required metadata file is present in spec directory;
	%if &filepath. ^= and %sysfunc(fileexist(&filepath.&II.&filename.)) = 0 %then %do;
		%put %str(ERR)%str(OR: xtcore.sas - input &filename. file was not found in &filepath.);
		%let end_xtcore = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xtcore. = Y %then %goto endmac;

	%*Load metadata information into macro variable;
	filename metadata "&filepath.&II.&filename." termstr = CRLF;

    proc import out = __tmp_&sysmacroname._var_0 datafile = metadata dbms = csv replace;
        guessingrows = max;
		delimiter = "$";
    run;

    %*Sort the dataset by expected specified variable order;
	proc sort data = __tmp_&sysmacroname._var_0 (where = (strip(lowcase(strip(dataset))) = "adsl"));
		by order;	  
    run;

	%if %symexist(drop_vars) %then %symdel drop_vars;
	%local drop_vars;

	proc sql noprint;
	    %*Define core variables;
		select variable into :core_vars separated by " " from __tmp_&sysmacroname._var_0 where lowcase(strip(core)) = "y";

		%*Get input dataset variable names; 
		create table __tmp_&sysmacroname._inds_vars as 
        	select name 
        	from dictionary.columns
        	where lowcase(memname) = lowcase("&inds.") and lowcase(libname) = "work" and lowcase(name) not in ("studyid", "usubjid");
		
		%*Find intersection between core variable names and input dataset variable names;
		create table __tmp_&sysmacroname._intersect_vars as
			select a.name 
			from __tmp_&sysmacroname._inds_vars as a left join __tmp_&sysmacroname._var_0 as b
			on lowcase(a.name) = lowcase(b.variable)
			where lowcase(strip(b.core)) = "y";

		%*If input dataset already includes core variables, then they will need to be dropped.;
		select name into :drop_vars separated by " " from __tmp_&sysmacroname._intersect_vars;
    quit;

	%*Merge ADSL to parent dataset;
	proc sort data = adam.adsl out = adsl;
		by usubjid;
	run;

    proc sort data = &inds.;
		by usubjid;
	run;

    data &outds.;
        merge &inds.(in = ina %if %symexist(drop_vars) %then drop = &drop_vars.;)
			  adsl(in = inb keep = usubjid &core_vars.);
        by usubjid;
        if ina and inb;
    run;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
	    proc datasets lib = work nolist;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xtcore;