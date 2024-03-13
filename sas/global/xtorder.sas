/************************************************************************************
* Program/Macro:             xtorder.sas
* Protocol:
* SAS Ver:                   SAS 9.4 V9
* Author:					 Oleksandr Homel
* Date:						 20JUL2022
* Program Title:
*
* Description:               Creates a global macro variable called &dsname.SORTSTRING.
* Remarks:
* Input:					 &filepath.&II.&filename. .csv spreadsheet
* Output:                    Global macro variable &dsname.SORTSTRING
*
* Parameters:                dsname - dataset to look for in the metadata file.
*							 filename - name of the CSV file with metadata. Determined automatically if that parameter is empty.
*							 filepath - full pass to CSV file with metadata.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*
* Sample Call:               %xtorder(ADSL);
*							 %xtorder(AE);
*
* Assumptions:
* Revisions:
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xtorder(dsname /*Required. Dataset to look for in the metadata file.*/,
			   filename= /*Optional. Name of the CSV file with metadata. Determined automatically if that parameter is empty.*/,
			   filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs /*Default: final/specs. Full pass to CSV file with metadata.*/,
			   debug=N /*Default: N. If N then delete temporary datasets.*/);

	%global &dsname.SORTSTRING;
	%local end_xtorder params_to_check i param_name param_value infile dscheck;

	%*Flag for premature macro termination;
	%let end_xtorder = N;

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
			%put %str(ERR)%str(OR: xtorder.sas - &param_name. is required parameter and should not be NULL);
			%let end_xtorder = Y;
		%end;
	%end;

	%*Determine the metadata file using the input name of the dataset;
	%if &filename. = %then %do;
	    %if %length(%cmpres(&dsname.)) = 2 or %index(%lowcase(&dsname.),supp) > 0 or %lowcase(%cmpres(&dsname.)) = relrec or (%length(%cmpres(&dsname.)) = 4 and %substr(%lowcase(%cmpres(&dsname.)), 1, 2) = ap) %then %do;
			%let infile = &filepath.&II.SDTM_spec_Datasets.csv;
		%end;
	    %else %do;
			%let infile = &filepath.&II.ADAM_spec_Datasets.csv;
		%end;
	%end;
	%else %do;
		%let infile = &filepath.&II.&filename.;
	%end;

	%*Check if metadata file is present in spec directory;
	%if %sysfunc(fileexist(&infile.)) = 0 %then %do;
		%put %str(ERR)%str(OR: xtorder.sas - input &filename. file was not found in &filepath.);
		%let end_xtorder = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xtorder. = Y %then %goto endmac;

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

    %*Create SORTSTRING macro variable if dataset exists;
	%if &dscheck. > 0 %then %do;
	    data _null_;
			set __tmp_&sysmacroname._1(where = (strip(lowcase(dataset)) = strip(lowcase("&dsname."))));
	    
	        call symputx(compress("&dsname." || "SORTSTRING"), translate(compress("Key Variables"n), " ", ","));
	    run;
	%end;
	%else %do;
		%put %str(ERR)%str(OR: xtorder.sas - &dsname. does not exist in &infile.. SORTSTRING variable is not created);
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
	    proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xtorder;