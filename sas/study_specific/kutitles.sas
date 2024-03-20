/************************************************************************************
* Program/Macro:             kutitles.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      17SEP2022
* Program Title:             
*
* Description:               Macro which assigns titles according to TFL_titles.csv file.
* Remarks:
* Input:                     TFL_titles.csv
* Output:                    title1-title5
*
* Parameters:                progname - name of the SAS program, which is used for search in TFL_titles.csv.
*							 filepath - full path to TFL_titles.csv.
* 							 seq - sequence number of the output in TFL_titles.csv file.
* 							 justify - option that determines the alignment of titles.
*							 escapechar - escape character.
* 							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %kutitles(s_000_ae3, seq=1);
*							 %kutitles(l_000_dm, seq=1);
*
* Assumptions:
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro kutitles(progname /*Required. Name of the SAS program, which is used for search in TFL_titles.csv.*/,
				filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs /*Default: final/specs. Full path to TFL_titles.csv.*/,
				seq=1 /*Default: 1. Sequence number of the output in TFL_titles.csv file.*/, 
				justify=c /*Default: c. Option that determines the alignment of titles.*/,
				escapechar=$ /*Default: $. Escape character.*/,
				debug=N /*Default: N. If N then delete temporary datasets.*/);

	%local end_kutitles params_to_check i param_name param_value nrows;

	%*Flag for premature macro termination;
	%let end_kutitles = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = progname filepath seq justify;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: kutitles.sas - &param_name. is required parameter and should not be NULL);
			%let end_kutitles = Y;
		%end;
	%end;

	%*Check if TFL_titles.csv is present in the directory;
	%if %sysfunc(fileexist("&filepath.&II.TFL_titles.csv")) = 0 %then %do;
		%put %str(ERR)%str(OR: kutitles.sas - TFL_titles.csv was not found in &filepath.);
		%let end_kutitles = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_kutitles. = Y %then %goto endmac;
	
	%*Remove all existing titles;
	title;
	
	%*Delete macro variables that are going to be used by that macro, title1-title5;
	%do i = 1 %to 5;
		%if %symexist(title&i.) %then %do;
			%symdel title&i.;
		%end;
	%end;

	%*Import titles file;
	proc import file="&filepath.&II.TFL_titles.csv" dbms = csv replace out = __tmp_&sysmacroname._1;
		guessingrows = max;
		datarow = 2;
		delimiter = ",";
		getnames = yes;
	run;

	%*Check if multiple records for unique program name and sequence present in TFL_titles.csv;
	proc sql noprint;
		select count(*) into: nrows from __tmp_&sysmacroname._1 where progname = "&progname." and seq = &seq.;
	quit;

	%if &nrows. = 0 %then %do;
		%put %str(ERR)%str(OR: kutitles.sas - no titles present for &progname. and seq=&seq. in TFL_titles.csv);
	%end;
	%else %do;
		%if &nrows. > 1 %then %do;
			%put %str(WAR)%str(NING: kutitles.sas - multiple rows present for &progname. and seq=&seq. in TFL_titles.csv);
		%end;

		%*Derive sponsor specific titles;
		data __tmp_&sysmacroname._2(drop = global:);
			set __tmp_&sysmacroname._1;

			retain title1 title2;

			if _N_ = 1 then do;
				if cmiss(globaltitle1, globaltitle2) = 0 then do;
					title1 = strip(globaltitle1);
					title2 = strip(globaltitle2);
				end;
				else do;
					put "WAR" "NING: kutitles.sas - title1 and title2 were not resolved due to missing GlobalTitle1 and GlobalTitle2 values in TFL_titles.csv";
				end;
			end;
		run; 

		%local title1 title2 title3 title4 title5;

		%*Create macro variables for titles assignment;
		data __tmp_&sysmacroname._&progname._&seq.;
			length title1-title5 $1000;
			set __tmp_&sysmacroname._2(where = (progname="&progname." and seq = &seq.));

			array titles {*} title1-title5;

			do i = 1 to dim(titles);
				%*Quoting titles if necessary;
				if not missing(titles[i]) then do;
					if index(titles[i], '"') = 0 then titles[i] = cats('"', titles[i], '"');
					if i = 1 then call symput(cat("title", strip(put(i, best.))), cat(" j=l ", %bquote(strip(titles[i])), " j=r 'Page &escapechar.{pageof}'"));
					else if i = 2 then call symput(cat("title", strip(put(i, best.))), cat(" j=l ", %bquote(strip(titles[i])), " j=r '&progname. &tmstmp_date.T&tmstmp_time.'"));
					else call symput(cat("title", strip(put(i, best.))), cat(" j=&justify. ", %bquote(strip(titles[i]))));
				end;
			end;
		run;

		%*Assign titles;
		%do i = 1 %to 5;
			%if %sysfunc(symexist(title&i.)) %then %do;
				title&i %unquote(&&title&i.);
			%end;
		%end;
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend kutitles;

