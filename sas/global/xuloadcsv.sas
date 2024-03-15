/************************************************************************************
* Program/Macro:             xuloadcsv.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksii Mikryukov
* Date:                      18JUL2022
* Program Title:             
*
* Description:               Make one dataset from a collection of raw .csv datasets.
*
* Remarks:                   filename should be defined as regular expression
* Input:                     csv rawdata file(s) in &filepath
* Output:                    &outds dataset
*
* Parameters:                filename - regular expression to filter the files in source directory.
*							 filepath - path to raw .csv datasets.
*							 splitchar - delimiter used in csv files.
*							 datarow - datarow option in import procedure.
*							 subjid - regular expression to parse filename and get subject id. Creates subjid_derived variable.
*							 visit - regular expression to parse filename and get visit. Creates visit_derived variable.
*							 outds - name of the output dataset.
*							 getnames - getnames option in import procedure.
*							 compress_names - option to remove spaces from variable names.
*							 debug - option to clean up intermediate datasets after macro execution.
*                            
* Sample Call:               %xuloadcsv(filename=%str(Clamp),subjid=%str(101-\d{3}),visit=%str(D\d+));
* 							 %xuloadcsv(filename=%str(^(?!.*(Dummy|PC|PK)).*csv$));
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xuloadcsv(filename /*Required. Regular expression to filter the files in source directory.*/, 
				 filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.raw&II.external /*Default: final/raw/external. Path to raw .csv datasets.*/, 
				 splitchar=$ /*Default: $. Delimiter used in .csv files.*/, 
				 datarow=2 /*Default: 2. Datarow option in import procedure.*/,
				 subjid= /*Optional. Regular expression to parse filename and get subject id.*/, 
				 visit= /*Optional. Regular expression to parse filename and get visit.*/, 
				 outds=raw_all /*Default: raw_all. Name of the output dataset.*/,
				 getnames=yes /*Default: yes. Getnames option in import procedure.*/,
				 compress_names=Y /*Default: Y. Option to remove spaces from variable names.*/,
				 debug=N /*Default: N. Option to clean up intermediate datasets after macro execution.*/);
	
	%local end_xuloadcsv params_to_check i param_name param_value __filenames_nobs fname_list curr_fname __fname __subjid __visit _var_length_statement;

	%*Flag for premature macro termination;
	%let end_xuloadcsv = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = filename filepath splitchar datarow outds getnames compress_names;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xuloadcsv.sas - &param_name. is required parameter and should not be NULL);
			%let end_xuloadcsv = Y;
		%end;
	%end;

	%if %lowcase(&getnames.) = yes and &datarow. < 2 %then %do;
		%put %str(ERR)%str(OR: xuloadcsv.sas - datarow should be 2 or greater if getnames = yes);
		%let end_xuloadcsv = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xuloadcsv. = Y %then %goto endmac;

	%*Create dataset with list of files in a given folder(lib), filtered by regex from filename;
	data __tmp_&sysmacroname._filenames;
		length fref $8 fname subjid_derived visit_derived $200;

		did = filename(fref, "&filepath.");
		did = dopen(fref);
		
		do i = 1 to dnum(did);
			fname = dread(did, i);
			if prxmatch("/&filename./", strip(fname)) and index(fname, "xlsx") = 0 and index(fname, "xlt") = 0 then do;
				subjid_derived = "_";
				%*Derive subjid_derived if the regular expression is specified.;
				%if &subjid. ^= %then %do;
					re1 = prxparse("/&subjid./");
					pos1 = prxmatch(re1, strip(fname));
					call prxposn(re1, 0, pos11, len1);
					if pos1 > 0 then subjid_derived = substr(strip(fname), pos11, len1);
				%end;

				visit_derived = "_";
				%*Derive visit_derived if the regular expression is specified.;
				%if &visit. ^= %then %do;
					re2 = prxparse("/&visit./");
					pos2 = prxmatch(re2, strip(fname));
					call prxposn(re2, 0, pos21, len2);
					if pos2 > 0 then visit_derived = substr(strip(fname), pos21, len2);
				%end;

				output;
			end;
		end;
		
		did = dclose(did);
		did = filename(fref);
	run;

	%*Count number of files;
	data _null_;
		if 0 then set __tmp_&sysmacroname._filenames nobs = n;
		call symputx("__filenames_nobs", n);
	run;
	
	proc sql noprint;
		select catx("#", fname, subjid_derived, visit_derived) into: fname_list separated by "," from __tmp_&sysmacroname._filenames;
	quit;

	%*Clean work directory if macro was already called and old datasets are kept using debug parameter;
	%if %sysfunc(exist(__tmp_&sysmacroname._raw_data_1)) %then %do;
		proc datasets library=work nowarn nolist;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%if &__filenames_nobs. > 0 %then %do;
		%*Iterate over files;
		%do i=1 %to %sysfunc(countw(%bquote(&fname_list.), %str(,)));
			
			%let curr_fname = %scan(%bquote(&fname_list.), &i., %str(,));
			%let __fname = %scan(%bquote(&curr_fname.), 1, %str(#));
			%let __subjid = %scan(%bquote(&curr_fname.), 2, %str(#));
			%let __visit = %scan(%bquote(&curr_fname.), 3, %str(#));

			%*If input files has variable names in first row;
			%if %lowcase(&getnames.) = yes and &datarow. > 1 %then %do;
				%*Import file with getnames - Y to get the names ;
				proc import file="&filepath.&II.&__fname." dbms=csv replace out=__tmp_&sysmacroname._raw_names_&i.;
					guessingrows = max;
					datarow = &datarow.;
					delimiter = "&splitchar.";
					getnames = yes;
				run;

				%*Get variable names and put them into macro variable;
				proc contents data=work.__tmp_&sysmacroname._raw_names_&i. noprint out=__tmp_&sysmacroname._names_&i.;
	   			run;

				%*Create macro variable for renaming;
				proc sql noprint;
					select cats("var", put(varnum, best.), "=", 
							%if %lowcase(&compress_names.) = y %then %do; compress(name, "_", "kda") %end; 
							%else %do; catt("'", name, "'n") %end;) 
								into: __tmp_&sysmacroname._var_rename_&i. separated by " " from __tmp_&sysmacroname._names_&i.;
				quit;
			%end;

			%*Actual import, importing without names for all variables to be character;
			proc import file="&filepath.&II.&__fname." dbms=csv replace out=__tmp_&sysmacroname._raw_data_&i.;
				guessingrows = max;
				datarow = 1;
				delimiter = "&splitchar.";
				getnames = no;
			run;

			data __tmp_&sysmacroname._raw_data_&i.;
				set __tmp_&sysmacroname._raw_data_&i. %if %lowcase(&getnames.) = yes %then %do; (rename = (&&__tmp_&sysmacroname._var_rename_&i.)) %end;;

				format _character_;

				%*Since files are imported together with headers, some records need to be removed from the top of the file;
				if _n_ < &datarow. then delete;

				length dataset_no 8 subjid_derived visit_derived $200;
				dataset_no = &i.;
				subjid_derived = "&__subjid.";
				visit_derived = "&__visit.";
			run;

			%*Get variable names and put them into macro variable;
			proc contents data=work.__tmp_&sysmacroname._raw_data_&i. noprint out=__tmp_&sysmacroname._names2_&i.;
   			run;

		%end;

		%*Choose max length for each variable;
		data __tmp_&sysmacroname._names;
			set __tmp_&sysmacroname._names2_:;
		run;

		proc sql noprint;
			create table __tmp_&sysmacroname._names2 as 
			select name, type, max(length) as max_len 
			from __tmp_&sysmacroname._names 
			group by name, type 
			order by varnum;

			select cat(%if %lowcase(&compress_names.) = y %then %do; compress(name, "_", "kda") %end; 
					   %else %do; catt("'", name, "'n") %end;, 
					   ifc(type = 1, " ", " $"), ifn(type = 1, max_len, max_len + 10)) 
					       into: _var_length_statement separated by " " from __tmp_&sysmacroname._names2;
		quit;

		%*Set all raw data together and assign max length for each var;
		data &outds.;
			length &_var_length_statement.;
			set __tmp_&sysmacroname._raw_data_:;

			%if &subjid. = %then drop subjid_derived;;
			%if &visit. = %then drop visit_derived;;
		run;
	%end;
	%else %do;
		%put WARNING: xuloadcsv.sas - read 0 datasets from &filepath. for regex = &filename.;

		data &outds.;
			length dataset_no 8 subjid_derived visit_derived $200;
			call missing(of _all_);
			if not missing(dataset_no);
			%if &subjid. = %then drop subjid_derived;;
			%if &visit. = %then drop visit_derived;;
		run;
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname._:;
		run;
	%end;

	%endmac:

%mend xuloadcsv;