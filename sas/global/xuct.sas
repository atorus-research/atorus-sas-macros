/************************************************************************************
* Program/Macro:             xuct.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksii Mikriukov
* Date:                      12AUG2022
* Program Title:             
*
* Description:               A program to check if variable has only the values specified in Codelists tab of spec and checks for 
* 							 compliance with CDISC SDTM Controlled terminology.
* Remarks:
* Input:                     &inds input dataset, _ct.sas7bdat SDTM Controlled Terminology dataset in the misc library
* Output:                    list of values that do not match SDTM Controlled Terminology, list of values that are not 
*							 in Codelists tab in spec, _ct.sas7bdat (if it's not already created)
*
* Parameters:                inds - name of the input dataset.
*							 invar - name of the variable in input dataset to be checked.
*							 codelist - codelist name as specified in ID column in codelists metadata file.
* 							 subset - logical condition to be used in where clause, when variable may have multiple codelists.
*							 filename - codelists metadata file (Codelists tab of spec converted to .csv file).
*							 filepath - path to codelists metadata file.
*							 ctfile - CDISC SDTM Controlled Terminology file converted to CSV.
*							 ctpath - path to path to CDISC SDTM Controlled Terminology file, if misc._ct.sas7bdat is missing.
*							 checkct - flag, that determines whether values should be checked for sompliance with CDISC SDTM CT.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xuct(cm, CMCAT, CMCAT, checkct = N);
* 							 %xuct(ex, EXDOSU, EX.UNIT, checkct = Y);
* 							 %xuct(lb, LBORRESU, LB.UNIT, checkct = Y);
*
* Assumptions:				 If codelist is applicable for multiple domains, such as UNIT applicable for EX/LB/CM/etc., then
*							 codelist ID in spec must be in DOMAIN.CODELIST format, i.e. EX.UNIT, LB.UNIT, CM.UNIT.
* 							 _ct.sas7bdat should be available in the misc library. If _ct.sas7bdat is not there, then CDISC 
* 							 SDTM Controlled Terminology spreadsheet with .csv extension (ctfile parameter) must be available in 
* 							 directory specified in ctpath parameter. Delimeter must be "$".
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 1				Oleksii Mikriukov			   18Oct2022		   1) Added &subset parameter
*																   2) Check data type of &invar in spec
* 																   3) Check if Codelists tab in spec has &codelist
************************************************************************************/

%macro xuct(inds /*Required. Input dataset name.*/,
			invar /*Required. Variable name that will be checked for CT.*/,
			codelist /*Required. Name of the codelist to be used.*/,
			subset=%str(1=1) /*Default: all observations. To be used when variable may have multiple codelists*/,
			filename=SDTM_spec_Codelists.csv /*Default: SDTM_spec_Codelists.csv. Defines source file to use.*/,
			filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs /*Default: final/specs. Indicates path to source file.*/,
			ctfile=SDTM Terminology.csv /*Default: SDTM Terminology.csv. Defines source CT file to be converted to misc._ct.sas7bdat, if _ct.sas7bdat not created yet.*/,
			ctpath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.raw&II.dict/*Default: final/raw/dict. Indicates path to CT csv file.*/,
			checkct=Y /*Default: Y. Defines whether variable values should checked for compliance with CDISC CT. If N, then values checked only for compliance with spec Codelist tab.*/, 
			debug=N /*Default: N. If Y then deletes temporary datasets.*/);

	%local end_xuct params_to_check i param_name param_value cl ct_cl xuct_cl_nobs xuct_ct_nobs;

	%*Flag for premature macro termination;
	%let end_xuct = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds invar codelist subset filename filepath;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xuct.sas - &param_name. is required parameter and should not be NULL);
			%let end_xuct = Y;
		%end;
	%end;

	%*Check whether required codelist metadata file is present in spec directory;
	%if %sysfunc(fileexist(&filepath.&II.&filename.)) = 0 %then %do;
		%put %str(ERR)%str(OR: xuct.sas - input &filename. file was not found in &filepath.);
		%let end_xuct = Y;
	%end;

	%*Check whether _ct.sas7bdat present in misc directory;
	%if %sysfunc(exist(misc._ct)) = 0 %then %do;
		%put %str(NO)%str(TE: xuct.sas - misc._ct data set does not exist. Trying to create it.);

		%if &ctfile. = %then %do;
			%put %str(ERR)%str(OR: xuct.sas - specify ctfile parameter to create _ct.sas7bdat in misc directory.);
			%let end_xuct = Y;
		%end;
		%else %do;
			%*If no _ct.sas7bdat found, then try to create from controlled terminology csv file;
			%if %sysfunc(fileexist(&ctpath.&II.&ctfile.)) ^= 0 %then %do;

				filename __tmp_CT "&ctpath.&II.&ctfile." termstr = CRLF;

				proc import out=_&sysmacroname._ct datafile = __tmp_CT dbms = csv replace;
					delimiter = "$";
					datarow = 2;
					getnames = no;
					guessingrows = max;
				run;

				proc sort data = _&sysmacroname._ct;
					by var4;
				run;

				data misc._ct;
					set _&sysmacroname._ct;
				run;
			%end;
			%*If no _ct.sas7bdat and not CT csv file found, then put message in log file;
			%else %if %sysfunc(fileexist(&filepath.&II.&ctfile.)) = 0 %then %do;
				%put %str(ERR)%str(OR: xuct.sas - Neither _ct.sas7bdat in misc nor &ctfile. in &ctpath. applicable);
				%let end_xuct = Y;
			%end;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xuct. = Y %then %goto endmac;

	data _null_;
		length codelist ct_codelist $40;

		%*Process codelists in DOMAIN.CODELIST format;
		if index("&codelist.", ".") ^= 0 then do;
			codelist = tranwrd("&codelist.", ".", "_");
			ct_codelist = strip(substr("&codelist.", index("&codelist.", ".") + 1));
		end;
		%*Otherwise, if no DOMAIN. part, then use CODELIST;
		else do;
			codelist = "&codelist.";
			ct_codelist = "&codelist.";
		end;

		call symput("cl", strip(codelist));
		call symput("ct_cl", strip(ct_codelist));
	run;

	%*Import spec codelist metafile;
	filename codelist "&filepath.&II.&filename." termstr = CRLF;

	proc import out=_&sysmacroname._cl_all datafile = codelist dbms = csv replace;
		delimiter = "$";
		datarow = 2;
		getnames = yes;
		guessingrows = max;
	run;

	%local data_type;
	%let data_type = character;

	%*Subset spec codelists, to include only terms for target variable invar;
	data _&sysmacroname._cl_&cl.(keep = ID Name "NCI Codelist Code"n "Data Type"n Term "NCI Term Code"n  "Decoded Value"n
								 rename = (ID = cl_id Name = cl_name "NCI Codelist Code"n = cl_nci_codelist_code "Data Type"n = cl_data_type Term = cl_term "NCI Term Code"n = cl_nci_term_code "Decoded Value"n = cl_decoded_value));
		set _&sysmacroname._cl_all;
		if lowcase(ID) = lowcase("&codelist.");

		if not missing("Data Type"n) then do;
			if lowcase("Data Type"n) in ("text", "datetime", "date", "time", "partialdate", "partialtime", "partialdatetime", "incompletedatetime", "durationdatetime", "intervaldatetime") then call symput("data_type", "character");
			else if lowcase("Data Type"n) in ("integer", "float") then call symput("data_type", "numeric");
			else do;
			put "ERR" "OR: xuct.sas - one or more rows have unknown Data Type for " ID " codelist. Please use applicable for define data types. Stop processing macro";
				call symput("end_xuct", "Y");
			end;
		end;
		else do;
			put "ERR" "OR: xuct.sas - one or more rows have empty Data Type for " ID " codelist. Please use applicable for define data types. Stop processing macro";
			call symput("end_xuct", "Y");
		end;
		%*If codelist in DOMAIN.CODELIST format, then trim DOMAIN. part;
		if index(ID, ".") ^= 0 then ID = strip(substr(ID, index(ID, ".") + 1));
	run;

	%*Check if Codelists tab has that specific codelist;
	proc sql noprint;
		select count(*) into :xuct_cl_nobs from _&sysmacroname._cl_&cl.;
	quit;

	%if &xuct_cl_nobs. = 0 %then %do;
		%put %str(WARN)%str(ING: xuct.sas - Codelist ID = %upcase(&codelist.) was not found in Codelists tab of the spec.);
	%end;

	%*Check spec codelists for non printable characters;
	data _null_;
		set _&sysmacroname._cl_&cl.;
		array charvars _character_;
		%*Create string with non-printable characters;
		%*In ASCII table there are 94 standard printable characters (decimal value range from 33 to 126) 
		  which represent letters, digits, punctuation marks. Decimal value 32 denotes the space between words
		  and is considered as an invisible graphic character.;
		%*The rest are considered as non printable/special characters;
		length _tmp_npchars $161;
		retain _tmp_npchars;
		if _N_ = 1 then do; 
			do _tmp_npchar_i = 0 to 31, 127 to 255;
				if _tmp_npchar_i = 0 then _tmp_npchars = byte(_tmp_npchar_i);
				else _tmp_npchars = trim(_tmp_npchars) || byte(_tmp_npchar_i);
            end;
        end;
        do over charvars;
			if indexc(charvars, _tmp_npchars) then put "WAR" "NING: xuct.sas - Non printable/special character found in %upcase(&codelist.) codelist: " charvars=;
        end;
	run;

	%*Merge spec CT to dataset;
	proc sql noprint undo_policy=none;
		create table _&sysmacroname._&cl. as 
			select * from &inds. left join _&sysmacroname._cl_&cl. 
			on %if &data_type = numeric %then %do; &inds..&invar. = input(_&sysmacroname._cl_&cl..cl_term, best.); %end;
				%else %do; &inds..&invar. = _&sysmacroname._cl_&cl..cl_term; %end;
	quit;

	data _&sysmacroname._&cl.;
		set _&sysmacroname._&cl. (where = (&subset.));
	run;		

	%if &checkct. = Y %then %do;
		%*Subset the CDISC CT for target variable;
		data _&sysmacroname._ct_&cl. (keep = var4);
			set misc._ct;
			if lowcase(var5) = lowcase("&ct_cl.");
		run;

		proc sql noprint;
			select count(*) into :xuct_ct_nobs from _&sysmacroname._ct_&cl.;
		quit;

		%if &xuct_ct_nobs. = 0 %then %do;
			%put %str(WARN)%str(ING: xuct.sas - Codelist ID = %upcase(&codelist.) was not found in CDISC CT list.);
		%end;

		data _&sysmacroname._ct_&cl.(keep = var1 var2 var4 var5 var6 ct_nci_preferred_term
				 					 rename = (var1 = ct_code var2 = ct_codelist_code var4 = ct_codelist_name var5 = ct_cdisc_submission_value var6 = ct_cdisc_synonym));
			merge misc._ct _&sysmacroname._ct_&cl.(in = b);
			by var4;
			if b;
			if not missing(var2);
			length ct_nci_preferred_term $256;
			ct_nci_preferred_term = strip(var8);
		run;

		%*Merge CDISC CT list to dataset;
		proc sql noprint undo_policy = none;
			create table _&sysmacroname._&cl. as 
				select * from _&sysmacroname._&cl. left join _&sysmacroname._ct_&cl. 
				on _&sysmacroname._&cl..&invar. = _&sysmacroname._ct_&cl..ct_cdisc_submission_value;
		quit;
	%end;

	%*Try to find synonyms from CT CDISC Synonym column;
	%if &checkct. = Y %then %do;

		data _&sysmacroname._&ct_cl._syn;
			set _&sysmacroname._ct_&cl.;
			length ct_cdisc_synonym_term $200;
			%*If CT CDISC Synonym column is not null and there are multiple synonyms;
			if not missing(ct_cdisc_synonym) and index(ct_cdisc_synonym, ";") ^= 0 then do;
				%*Then iterate over individual terms;
				do _tmp_i = 1 to count(ct_cdisc_synonym, ";") + 1;
					%*And output each of them;
					ct_cdisc_synonym_term = strip(scan(ct_cdisc_synonym, _tmp_i, ";"));
					output;
				end;
			end;
			%*Otherwise, if only one synonym, then keep it;
			else if not missing(ct_cdisc_synonym) then do;
				ct_cdisc_synonym_term = strip(ct_cdisc_synonym);
				output;
			end;
			%*Otherwise, if no synonyms found, then keep CDISC submission value;
			else if not missing(ct_cdisc_submission_value) then do;
				ct_cdisc_synonym_term = strip(ct_cdisc_submission_value);
				output;
			end;
		run;

		%*Merge synonyms to dataset;
		proc sql noprint undo_policy = none;
			create table _&sysmacroname._&cl. as 
				select a.*, b.ct_cdisc_submission_value as ct_suggest 
				from _&sysmacroname._&cl. as a left join _xuct_&ct_cl._syn as b 
				on lowcase(_&sysmacroname._&cl..&invar.) = strip(lowcase(_xuct_&ct_cl._syn.ct_cdisc_synonym_term));
		quit;
	%end;

	%*Remove duplicate records, to put messages once per term;
	proc sort data = _&sysmacroname._&cl. nodupkey;
		by &invar.;
	run;

	%*Prepare report and put messages to log file;
	data _&sysmacroname._&cl._report;
		set _&sysmacroname._&cl.;

		length ctmissfl clmissfl $1;

		if missing(ctmissfl) then call missing(ctmissfl);
		if missing(clmissfl) then call missing(clmissfl);
		if missing(ct_cdisc_submission_value) then call missing(ct_cdisc_submission_value);

		if not missing(&invar.) then do;
			%if &checkct. = Y %then %do;
				if missing(ct_cdisc_submission_value) then do;
					if not missing(cl_term) then do;
						put "NO" "TE: xuct.sas - %upcase(&inds..&invar)=" &invar. "not found in CDISC CT, but in %upcase(&codelist.) codelist.";
						put "NO" "TE: xuct.sas - Please check whether %upcase(&codelist.) codelist is extensible and there is no suitable CDISC submission value.";
						call missing(ctmissfl);
					end;
					else do;
						if not missing(ct_suggest) then do;
							put "WARN" "ING: xuct.sas - %upcase(&inds..&invar)=" &invar. "not found in CDISC CT. Check whether " ct_suggest "value should be used for remap";
						end;
						else do;
							put "WARN" "ING: xuct.sas - %upcase(&inds..&invar)=" &invar. "not found in CDISC CT. Check CDISC CT for possible values or add " &invar. "to %upcase(&codelist.) codelist in spec";
						end;
						ctmissfl = "Y";
					end;
				end;
			%end;

			if missing(cl_term) then do;
				if not missing(ct_cdisc_submission_value) then put "WARN" "ING: xuct.sas - %upcase(&inds..&invar)=" &invar. "not found in %upcase(&codelist.) codelist, but found in CDISC CT. Add " &invar. "value to %upcase(&codelist.) codelist in spec.";
				else put "WARN" "ING: xuct.sas - %upcase(&inds..&invar)=" &invar. "not found in %upcase(&codelist.) codelist in spec";
				clmissfl = "Y";
			end;
		end;
	run;

	%local _nobs_ctmiss_&cl. _nobs_clmiss_&cl.;

	%let _nobs_ctmiss_&cl. = 0;
	%let _nobs_clmiss_&cl. = 0;

	%if &checkct. = Y %then %do;
		proc sort data = _&sysmacroname._&cl._report 
				  out = _&sysmacroname._&cl._ctmiss (keep = &invar. ct_cdisc_submission_value ct_suggest ct_nci_preferred_term) nodupkey;
			by &invar. ct_suggest;
			where ctmissfl = "Y";
		run;

		proc sql noprint;
			select count(*) into :_nobs_ctmiss_&cl. from _&sysmacroname._&cl._ctmiss;
		quit;
	%end;

	proc sort data = _&sysmacroname._&cl._report out = _&sysmacroname._&cl._clmiss (keep = &invar. %if &checkct. = Y %then ct_code ct_codelist_code ct_codelist_name ct_cdisc_submission_value ct_nci_preferred_term;) nodupkey;
		by &invar.;
		where clmissfl = "Y";
	run;

	proc sql noprint;
		select count(*) into :_nobs_clmiss_&cl. from _&sysmacroname._&cl._clmiss;
	quit;

	%local __origls;
			
	%*Get original linesize option value;
	%let __origls = %sysfunc(getoption(linesize));

	options linesize = max;

	%if &&_nobs_ctmiss_&cl. ^= 0 %then %do;
		title "Term in %upcase(&inds..&invar) and not in CT";

		proc print data = _&sysmacroname._&cl._ctmiss noobs;
		run;

		title;
	%end;

	%if &&_nobs_clmiss_&cl. ^= 0 %then %do;
		title "Term in %upcase(&inds..&invar) and not in Codelist tab";

		proc print data = _&sysmacroname._&cl._clmiss noobs;
		run;

		title;
	%end;

	%*Restore original linesize option;
	options linesize=&__origls.;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete _&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xuct;
