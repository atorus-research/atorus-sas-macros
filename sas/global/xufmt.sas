/************************************************************************************
* Program/Macro:             xufmt.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      13JUL2022
* Program Title:             
*
* Description:               Create SAS formats from spec Codelist tab
* Remarks:					 
* Input:                     SDTM_spec_Codelist.csv or ADaM_spec_Codelist.csv
* Output:                    SAS formats from spec Codelist tab
*
* Parameters:                fmt - format name(s) to get from file specified in filename.
* 							 filename - indicates source file to use: SDTM_spec_Codelist.csv or ADaM_spec_Codelist.csv.
* 							 filepath - indicates path to source file.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xufmt(VSPARAM, ADaM_spec_Codelist.csv);
* 							 %xufmt(RACE SEX, SDTM_spec_Codelist.csv);
*
* Assumptions:               SDTM_spec_Codelist.csv or ADaM_spec_Codelist.csv should be already created
* 							 in spec directory.
* 							 Maximum length of codelist name should not exceed 29 characters.
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xufmt(fmt /*Required. Defines codelist names to create formats for.*/,			 
			 filename /*Required. Defines source file to use.*/,
			 filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.final&II.specs /*Default: final/specs. Indicates path to source file.*/,
			 debug=N /*Default: N. If Y then deletes temporary datasets.*/);

	%local end_xufmt params_to_check i param_name param_value id;

	%*Flag for premature macro termination;
	%let end_xufmt = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = fmt filename filepath;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xufmt.sas - &param_name. is required parameter and should not be NULL);
			%let end_xufmt = Y;
		%end;
	%end;

	%*Check whether required codelist metadata file is present in spec directory;
	%if %sysfunc(fileexist(&filepath.&II.&filename.)) = 0 %then %do;
		%put %str(ERR)%str(OR: xufmt.sas - input &filename. file was not found in &filepath.);
		%let end_xufmt = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xufmt. = Y %then %goto endmac;

	%*Import codelist metafile;
	filename codelist "&filepath.&II.&filename." termstr = CRLF;

	proc import out = __tmp_&sysmacroname._cl_0 datafile = codelist dbms = csv replace;
		delimiter = "$";
		getnames = yes;
		guessingrows = max;
	run;

	proc sort data = __tmp_&sysmacroname._cl_0;
		by id;
	run;
	
	%*Combine macro variable for where condition. Get values of fmt parameters and wrap it in quotation marks.;
	%*Also change multiple spaces between values into one space.;
	%let id = "%sysfunc(tranwrd(%sysfunc(compbl(&fmt.)), %str( ), " "))";

	%*CSV column names read with spaces. Rename;
	data __tmp_&sysmacroname._cl_1;
		set __tmp_&sysmacroname._cl_0 (where = (lowcase(id) in (%lowcase(&id.))));
		by id;
		%*Check for non printable characters;
		array charvars term id "Decoded Value"n;
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
			if indexc(charvars, _tmp_npchars) then do;
				put "WAR" "NING: xufmt.sas - Non printable/special character found " charvars= "Formats wont be created for this term";
				delete;
			end;
        end;

		%*Make sure no formats will have legit name;
		if index(id, ".") ^= 0 then do;
			if first.id then put "NO" "TE: xufmt.sas - ID contains . It is compressed in format names.";
			id = compress(id, ".");
		end;

		%*Make sure ID length do not exceed 29 characters long, so format names wont violate SAS naming restrictions;
		if length(id) > 29 then do;
			put "WARN" "ING: xufmt.sas - ID length should not exceed 29 characters. Format wont be created for ID = " id;
			delete;
		end;

		rename "Decoded Value"n = decoded_value;
	run;

	%*Create formats from codelists;
	data __tmp_&sysmacroname._cl_2;
		set __tmp_&sysmacroname._cl_1;
      
		length fmtname $31 type $20 start label $200.;

		%*Set hlo to avoid unwanted range interpretations by proc format;
		hlo = "";
		if not missing(order) then do;
			if strip(term) ^= "" then do;
				%*One format for order to term;
				fmtname = strip(id)||"OT";
				start = strip(put(order, ?? best.));
				label = strip(term);
				type = "n";
				output;
				%*One format for term to order;
				fmtname = strip(id)||"TO";
				type = "i";
				start = strip(term);
				label = strip(put(order, ?? best.));
				output;
			end;
			if strip(decoded_value) ^= "" then do;
				%*One format for order to decod;
				fmtname = strip(id)||"OD";
				start = strip(put(order, ?? best.));
				label = strip(decoded_value);
				type = "n";
				output;
				%*One format for decod to order;
				fmtname = strip(id)||"DO";
				type = "i";
				start = strip(decoded_value);
				label = strip(put(order, ?? best.));
				output;
			end;
		end;

		if strip(term) ^= "" and strip(decoded_value) ^= "" then do;
			%*One format for decoded_value to term;
			fmtname = strip(id)||"DT";
			type = "c";
			start = strip(decoded_value);
			label = strip(term);
			output;
			%*One format for term to decoded_value;
			fmtname = strip(id)||"TD";
			type = "c";
			start = strip(term);
			label = strip(decoded_value);
			output;
		end;
      
	run;

	%*Sort;
	proc sort data = __tmp_&sysmacroname._cl_2 out = __tmp_&sysmacroname._cl_3 (keep = fmtname start type label hlo) nodupkey;
		by fmtname start type label;
	run;

	%*Remove formats with non-unique start/label combinations;
	proc sql noprint;
		create table __tmp_&sysmacroname._cl_4 as 
			select distinct fmtname, type, start, label, hlo, count(start) as n 
			from __tmp_&sysmacroname._cl_3 
			group by fmtname, start;

		create table __tmp_&sysmacroname._cl as 
			select distinct fmtname, type, start, label, hlo, max(n) as unique from __tmp_&sysmacroname._cl_4 
			group by fmtname 
			order by fmtname, type, start, label;
	quit;

	proc format cntlin = __tmp_&sysmacroname._cl (where = (unique = 1)); 
	quit;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname._:;
		run;
	%end;

	%endmac:

%mend xufmt;