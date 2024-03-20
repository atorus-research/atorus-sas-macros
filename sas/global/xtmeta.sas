/************************************************************************************
* Program/Macro:             xtmeta.sas
* Protocol:
* SAS Ver:                   SAS 9.4 V9
* Author:					 Atorus Research
* Date:						 20JUL2022
* Program Title:
*
* Description:               Creates a zero record dataset based on a dataset metadata spreadsheet.
*							 Also creates a global macro variable called &dsname.KEEPSTRING.
* Remarks:
* Input:					 &filepath.&II.&filename. .csv spreadsheet
* Output:					 Zero record EMPTY_&dsname, global macro variable &dsname.KEEPSTRING
* 
* Parameters:                dsname - dataset to look for in the metadata file.
*							 filename - name of the CSV file with metadata. Determined automatically if that parameter is empty.
*							 filepath - full pass to CSV file with metadata.
*							 qc - flag, that changes all character variables length to 200.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*
* Sample Call:               %xtmeta(ADSL);
*							 %xtmeta(AE);
*
* Assumptions:
* Revisions:
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xtmeta(dsname /*Required. Dataset to look for in the metadata file.*/,
			  filename= /*Optional. Name of the CSV file with metadata. Determined automatically if that parameter is empty.*/,
			  filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs /*Default: final/specs. Full pass to CSV file with metadata.*/,
			  qc=N /*Default: N. If Y then changes all character variables length to 200.*/,
			  debug=N /*Default: N. If N then delete temporary datasets.*/);

    %global &dsname.KEEPSTRING;
	%local end_xtmeta params_to_check i param_name param_value infile dscheck vars;

	%*Flag for premature macro termination;
	%let end_xtmeta = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = dsname filepath;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xtmeta.sas - &param_name. is required parameter and should not be NULL);
			%let end_xtmeta = Y;
		%end;
	%end;

	%*Determine the metadata file using the input name of the dataset;
	%if &filename. = %then %do;
	    %if %length(%cmpres(&dsname.)) = 2 or %index(%lowcase(&dsname.), supp) > 0 or %lowcase(%cmpres(&dsname.)) = relrec or (%length(%cmpres(&dsname.)) = 4 and %substr(%lowcase(%cmpres(&dsname.)), 1, 2) = ap) %then %do;
			%let infile = &filepath.&II.SDTM_spec_Variables.csv;
		%end;
	    %else %do;
			%let infile = &filepath.&II.ADAM_spec_Variables.csv;
		%end;
	%end;
	%else %do;
		%let infile = &filepath.&II.&filename.;
	%end;

	%*Check if metadata file is present in spec directory;
	%if %sysfunc(fileexist(&infile.)) = 0 %then %do;
		%put %str(ERR)%str(OR: xtmeta.sas - input &filename. file was not found in &filepath.);
		%let end_xtmeta = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xtmeta. = Y %then %goto endmac;

	filename metadata "&infile." termstr = CRLF;

    proc import out = __tmp_&sysmacroname._1 datafile = metadata dbms = csv replace;
        guessingrows = max;
		delimiter = "$";
    run;

	%*Check if dataset exists in metadata file;
	proc sql noprint;
		select strip(put(count(*), best.)) into: dscheck from __tmp_&sysmacroname._1
			where strip(lowcase(dataset)) = strip(lowcase("&dsname."));
	quit;

    %*Create KEEPSTRING macro variable and EMPTY_&dsname. dataset if dataset exists;
	%if &dscheck. > 0 %then %do;
		%*Sort the dataset by expected specified variable order;
	    proc sort data = __tmp_&sysmacroname._1 sortseq = linguistic(numeric_collation = on);
			where (strip(lowcase(dataset)) = strip(lowcase("&dsname.")) and lowcase("Use (y)"n) = "y");
			by order;
	    run;

		%local miss_len len_type;
		proc sql noprint;
			select distinct variable into :miss_len separated by ", " 
			from __tmp_&sysmacroname._1
			where missing(length);

			select lowcase(type) into: len_type
			from sashelp.vcolumn
			where lowcase(libname) = "work" and lowcase(memname) = lowcase("__tmp_&sysmacroname._1") and lowcase(name) = "length";
		quit;

		%if %length(&miss_len) ^= 0 %then %do;
			%put %str(NO)%str(TE: xtmeta.sas - Length is not filled for &miss_len.);
		%end;

	    %*Create KEEPSTRING macro variable and load metadata information into macro variables;
	    data _null_;
			set __tmp_&sysmacroname._1 nobs = nobs end = eof;

	        if _n_ = 1 then call symputx("vars", compress(put(nobs, best.)));
	    
	        call symputx("var" || compress(put(_n_, best.)), strip(variable));
	        call symputx("label" || compress(put(_n_, best.)), strip(label));

	        %*Valid 'Data Type'n includes INTEGER, FLOAT, NUM, TEXT, CHAR, DATE, DATETIME, TIME to map to SAS numeric or character type;
	        if lowcase("Data Type"n) in ("integer", "float") then call symputx("data_type" || compress(put(_n_, best.)), "");
	        else if lowcase("Data Type"n) in ("text", "datetime", "date", "time", "partialdate", "partialtime", "partialdatetime", "incompletedatetime", "durationdatetime", "intervaldatetime") then call symputx("data_type" || compress(put(_n_, best.)), "$");
	        else put "WAR" "NING: xtmeta.sas - wrong data type." 'Data Type'n = ;

			%if &qc. = N %then %do;
				if missing(length) then do;
					if lowcase("Data Type"n) in ("text", "datetime", "date", "time", "partialdate", "partialtime", "partialdatetime", "incompletedatetime", "durationdatetime", "intervaldatetime") then call symputx("length" || compress(put(_n_, best.)), compress(put(200, best.)));
					else call symputx("length" || compress(put(_n_, best.)), compress(put(8, best.)));
				end;
				%if %lowcase(&len_type.) ^= char %then %do; else if not missing(length) then call symputx("length" || compress(put(_n_, best.)), compress(put(length, best.))); %end;
			%end;
			%if &qc. = Y %then %do;
				if lowcase("Data Type"n) in ("text", "datetime", "date", "time", "partialdate", "partialtime", "partialdatetime", "incompletedatetime", "durationdatetime", "intervaldatetime") then call symputx("length" || compress(put(_n_, best.)), compress(put(200, best.)));
				else call symputx("length" || compress(put(_n_, best.)), compress(put(8, best.)));
			%end;

			%if %length(%cmpres(&dsname.)) ^= 2 and %index(%lowcase(&dsname.), supp) = 0 and %lowcase(%cmpres(&dsname.)) ^= relrec and not (%length(%cmpres(&dsname.)) = 4 and %substr(%lowcase(%cmpres(&dsname.)), 1, 2) = ap) %then %do;
				if not missing(format) then call symputx("format" || compress(put(_n_, best.)), strip(format));
			%end;

	        %*Create KEEPSTRING macro variable;
	        length keepstring $32767;	 
	        retain keepstring;
		
	        keepstring = compress(keepstring) || "|" || compress(variable); 
	        if eof then call symputx(upcase(compress("&dsname." || "KEEPSTRING")), translate(compress(keepstring), " ", "|"));
	    run;
	     
	    %*Create a 0-observation dataset used for assigning variable attributes to the actual dataset;
	    data EMPTY_&dsname.;
			%do i = 1 %to &vars.;
				attrib &&var&i. label = "&&label&i." length = &&data_type&i.&&length&i. %if %symexist(format&i.) %then %do; format = &&format&i. %end;;
			%end;
			call missing(of _all_);
	        if 0;
		run;
	%end;
	%else %do;
		%put %str(ERR)%str(OR: xtmeta.sas - &dsname. does not exist in &infile.. KEEPSTRING and EMPTY_&dsname. are not created);
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
	    proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xtmeta;