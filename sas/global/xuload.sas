/************************************************************************************
* Program/Macro:             xuload.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksandr Homel
* Date:                      13JUL2022
* Program Title:             
*
* Description:               Macro which uploads datasets to SAS working directory, applies sorting order,
*							 and removes process input formats/informats.
* Remarks:
* Input:                     &inds input dataset(s) from &sourcelib library
* Output:                    &inds dataset(s)
*
* Parameters:                inds - name(s) of the input dataset(s).
*							 sourcelib - name of the input library.
*							 sortvars - sort order for the dataset.
*							 encoding - encoding for the dataset.
*							 mode - (smart/keep/remove) format/informat processing mode.
*							 fmtlib - library with .sas7bcat format catalogs.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xuload(dm ae, crf, encoding=asciiany, mode=keep, fmtlib=crf);
*							 %xuload(dm, sdtm, sortvars=usubjid);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 
************************************************************************************/

%macro xuload(inds /*Required. Name(s) of the input dataset(s).*/,
			  sourcelib /*Required. Name of the input library.*/,
			  sortvars= /*Optional. Sort order for the dataset.*/,
			  encoding= /*Optional. Encoding for the dataset.*/,
			  mode=smart /*Default: smart. Format/informat processing mode (smart/keep/remove).*/,
			  fmtlib=&sourcelib. /*Default: &sourcelib. Library with .sas7bcat format catalogs. Used if mode = keep.*/,
			  debug=N /*Default: N. If N then delete temporary datasets.*/);

	%local end_xuload params_to_check i param_name param_value nwrd catcheck catname fmtlibres wrd rmfmt rminfmt;

	%*Flag for premature macro termination;
	%let end_xuload = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds sourcelib mode;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xuload.sas - &param_name. is required parameter and should not be NULL);
			%let end_xuload = Y;
		%end;
		%else %do;
			%*Check whether mode parameter has expected values;
			%if %lowcase(&param_name.) = mode %then %do;
				%if %lowcase(&param_value.) ^= smart and %lowcase(&param_value.) ^= keep and %lowcase(&param_value.) ^= remove %then %do;
					%put %str(ERR)%str(OR: xuload.sas - parameter &param_name. should be smart, keep or remove);
					%let end_xuload = Y;
				%end;
				%*Parameter fmtlib is conditionally required, if mode = keep;
				%else %if %lowcase(&param_value.) = keep and &fmtlib. = %then %do;
					%put %str(ERR)%str(OR: xuload.sas - fmtlib parameter should not be NULL if &param_name. = &param_value.);
					%let end_xuload = Y;
				%end;
			%end;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xuload. = Y %then %goto endmac;

	%*Count number of datasets specified in INDS parameter;
	%let nwrd = %sysfunc(countw(&inds.));

	%*Smart mode removes unexpected formats/informats from variables in input dataset;
	%if %lowcase(&mode.) = smart %then %do;
		%put %str(NO)%str(TE: xuload.sas - smart mode is used. Macro will remove all unexpected formats/informats from variables);
		proc sql noprint;
			%*Get valid SAS formats;
			create table __tmp_&sysmacroname._fmt as
				select fmtname as format from sashelp.vformat where lowcase(fmttype) = "f" order by format;
			%*Get valid SAS informats;
			create table __tmp_&sysmacroname._infmt as
				select fmtname as informat from sashelp.vformat where lowcase(fmttype) = "i" order by informat;
		quit;
	%end;
	%*Keep mode tries to upload and use .sas7bcat file with formats. If file does not exist then uploads the dataset as is;
	%if %lowcase(&mode.) = keep %then %do;
		%put %str(NO)%str(TE: xuload.sas - keep mode is used. Macro will look for .sas7bcat catalog in %upcase(&fmtlib.) library to upload unexpected formats. If .sas7bcat catalog does not exist, macro uploads the dataset as is);
		proc sql noprint;
			select count(*) into: catcheck from sashelp.vcatalg
			where lowcase(libname) = lowcase("&fmtlib.") and lowcase(memtype) = "catalog";
			%if &catcheck. > 0 %then %do;
				create table __tmp_&sysmacroname._ctlg as
					select distinct(memname) from sashelp.vcatalg
					where lowcase(libname) = lowcase("&fmtlib.") and lowcase(memtype) = "catalog";

				select strip(memname) into: catname separated by " " from __tmp_&sysmacroname._ctlg;
			%end;
		quit;
		
		%if &catcheck. > 0 %then %do;
			%put %str(NO)%str(TE: xuload.sas - catalog(s) %upcase(&catname.) was found in %upcase(&fmtlib.) library and was used to apply formats);
			%*Get fmtsearch value before reassignment;
			%let fmtlibres = %sysfunc(getoption(fmtsearch));

			options fmtsearch = (&fmtlib.);
		%end;
		%else %do;
			%put %str(NO)%str(TE: xuload.sas - .sas7bcat catalog was not found in %upcase(&fmtlib.) library. Use mode = smart or mode = remove if any unexpected formats/informats present);
		%end;
	%end;
	%*Remove mode removes all existing formats/informats from variables in input dataset;
	%if %lowcase(&mode.) = remove %then %do;
		%put %str(NO)%str(TE: xuload.sas - remove mode is used. Macro will remove all existing formats/informats from variables);
	%end;

	%*Loop to process each dataset name;
	%do i = 1 %to &nwrd.;
		
		%*Put dataset name into the macro variable;
		%let wrd = %scan(&inds., &i.);

		%*Check if dataset is present in library;
		%if %sysfunc(exist(&sourcelib..&wrd.)) = 0 %then %do;
			%put %str(ERR)%str(OR: xuload.sas - dataset %upcase(&wrd.) was not found in %upcase(&sourcelib.) library);
		%end;
		%else %do;
			%if %lowcase(&mode.) = smart %then %do;
				%*Check if dataset variables contain unexpected formats/informats;
				%*Get formats and informats from input dataset;
				proc contents data = &sourcelib..&wrd. %if &encoding. ^= %then %do; (encoding = &encoding.) %end; out = __tmp_&sysmacroname._&wrd._1(keep = name format informat where = (cmiss(format,informat) ^= 2)) noprint;
				run;

				proc sort data = __tmp_&sysmacroname._&wrd._1;
					by format;
				run;

				%*Get list of variables with unexpected formats;
				data __tmp_&sysmacroname._&wrd._2(keep = name);
					merge __tmp_&sysmacroname._&wrd._1(in = a where = (not missing(format))) __tmp_&sysmacroname._fmt(in = b);
					by format;
					if a and not b;
				run;

				proc sort data = __tmp_&sysmacroname._&wrd._1;
					by informat;
				run;

				%*Get list of variables with unexpected informats;
				data __tmp_&sysmacroname._&wrd._3(keep = name);
					merge __tmp_&sysmacroname._&wrd._1(in = a where = (not missing(informat))) __tmp_&sysmacroname._infmt(in = b);
					by informat;
					if a and not b;
				run;

				%let rmfmt = ;
				%let rminfmt = ;

				proc sql noprint;
					select strip(name) into: rmfmt separated by " " from __tmp_&sysmacroname._&wrd._2;
					select strip(name) into: rminfmt separated by " " from __tmp_&sysmacroname._&wrd._3;
				quit;
			%end;

			%*Upload the dataset from the library;
			data &wrd.;
				set &sourcelib..&wrd. %if &encoding. ^= %then %do; (encoding = &encoding.) %end;;
					%if %lowcase(&mode.) = smart %then %do;
						%*Remove unexpected formats;
						%if &rmfmt. ^= %then %do;
							format &rmfmt.;
							%put %str(NO)%str(TE: xuload.sas - %upcase(&wrd.) unexpected formats were removed from &rmfmt.);
						%end;
						%*Remove unexpected informats;
						%if &rminfmt. ^= %then %do;
							informat &rminfmt.;
							%put %str(NO)%str(TE: xuload.sas - %upcase(&wrd.) unexpected informats were removed from &rminfmt.);
						%end;
					%end;
					%if %lowcase(&mode.) = remove %then %do;
						format _all_;
						informat _all_;
					%end;
			run;

			%*Sort the dataset, if sort order is specified;
			%if &sortvars. ^= %then %do;
				proc sort data = &wrd. out = &wrd.;
					by &sortvars.;
				run;
			%end;
		%end;
	%end;

	%if %lowcase(&mode.) = keep and &catcheck. > 0 %then %do;
		%*Set default library for formats back;
		options fmtsearch = &fmtlibres.;
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
	    proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xuload;