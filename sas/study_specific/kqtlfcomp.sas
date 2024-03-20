/************************************************************************************
* Program/Macro:             kqtlfcomp.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      09SEP2021
* Program Title:             
*
* Description:               Macro which compares TLF datasets
* Remarks:
* Input:                     &output dataset from &prod_lib and &qc_lib
* Output:                    find_&output dataset
*
* Parameters:                output - output name. The macro will look for that dataset name in the prod_lib. For the qc lib, it will look for the index of that dataset name.
*                            prod_lib - library of the production output dataset.
*                            qc_lib - library of the qc output dataset.
*                            qc_output - specify when you want to manually select your dataset, can be left empty if you assumed the same name as the production.
*                            where - allows the user to specify a where statement to facilitate investitations e.g. where=%str(lbcat="HEMATOLOGY").
*                            prod_drop - specifies which variables have to be dropped from the production. Not advisable to use.
*                            dropchecked - specifies whether qcer dropped and checked any variables from production dataset before comparing.
*                            ignspl - Y/N. If Y then the comparison changes every split character to a space.
*                            chrspl - specifies the split character (e.g. chrspl=|).
*                            ignspc - Y/N. If Y then the comparison strips and compbl the results before comparing. Thereby ignoring any alignment differences between production and qc.
*                            ignlbl - Y/N. If Y then the comparison removes the variable labels before comparing.
*                            ignln - Y/N. If Y then ignores variable lengths while comparing.
*                            ignfor - Y/N. If Y then the comparison removes the variable formats before comparing.
*                            ignifor - Y/N. If Y then the comparison removes the variable informats before comparing.
*                            compress - Y/N. If Y then the comparison removes all spaces before comparing. Defaulted to N because removing all spaces can lead to numerical reading issues;
* 							 crit - specifies the criterion for the compare procedure.
*                            debug - Y/N. Can be switched to Y when the macro produces errors, to allow debugging.
*
* Sample Call:               %kqtlfcomp(output=t_14_3_1_1,
*							            prod_drop=rowlbl,
*							            dropchecked=Y,
*							            prod_lib=tfl,
*							            qc_lib=work,
*							            qc_output=t_14_3_1_1,
*							            where=1,
*							            ignspl=Y,
*							            chrspl=|,
*							            ignln=N,
*							            ignspc=N,
*							            ignlbl=Y,
*							            ignfor=Y,
*							            ignifor=Y,
*							            compress=Y,
*							            debug=N)
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro kqtlfcomp(output= /*Output name. The macro will look for that dataset name.*/,
                 prod_drop= /*Optional. Specifies which variables have to be dropped from the pruduction dataset.*/,
                 dropchecked=N /*Default: N. Specifies whether qcer dropped and checked any variables from production dataset.*/,
                 prod_lib=tfl /*Default: tfl. Library of the production output dataset.*/,
                 qc_lib=vtfl /*Default: vtfl. Library of the qc output dataset.*/,
                 qc_output= /*Optional. pecify when you want to manually select your dataset.*/,
                 where=1 /*Default: 1. Specify a where statement to facilitate investitations.*/,
                 ignspl=Y /*Default: Y. If Y then the comparison changes every split character to a space.*/,
                 chrspl=| /*Default: |. Split character.*/,
                 ignln=Y /*Default: Y. If Y then ignores variable lengths while comparing.*/,
                 ignspc=N /*Default: N. If Y then the comparison strips and compbl the results before comparing.*/,
                 ignlbl=Y /*Default: Y. If Y then the comparison removes the variable labels before comparing.*/,
                 ignfor=Y /*Default: Y. If Y then the comparison removes the variable formats before comparing.*/,
                 ignifor=Y /*Default: Y. If Y then the comparison removes the variable informats before comparing.*/,
                 compress=N /*Default: N. If Y then the comparison removes all spaces before comparing.*/,
				 crit= /*Optional. Specifies the criterion for the compare procedure.*/,
                 debug=N /*Default: N. If Y then keep temporary datasets to allow debugging.*/);

	proc datasets nolist nowarn;
		delete dif_:;
	run;

	%local end_kqtlfcomp params_to_check i param_name param_value output2 yncheck yncheck1 yncheck2 j;

	%*Flag for premature macro termination;
	%let end_kqtlfcomp = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = output prod_lib qc_lib qc_output;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: kqtlfcomp.sas - &param_name. is required parameter and should not be NULL);
			%let end_kqtlfcomp = Y;
		%end;
	%end;

	%let output2 = %sysfunc(substr(&output., 1, %sysfunc(min(27,%length(&output.)))));

	%*Quick macro parameter check, specify Y/N macro parameters here;
	%let yncheck = dropchecked ignspl ignspc ignlbl ignfor ignifor compress debug ignln; 

	%*Iterate through parameters;
	%do j = 1 %to %sysfunc(countc(&yncheck., %str( ))) + 1;
		%*Sub-select macro name;
		%let yncheck1 = %scan(&yncheck., &j., %str( ));
		%*Sub-select macro value;
		%let yncheck2 = &%scan(&yncheck., &j., %str( ));

		%*Check what the entry was;
		%if %upcase(&yncheck2.) ^= Y and %upcase(&yncheck2.) ^= N %then %do;
			%put %str(ERR)%str(OR: kqtlfcomp.sas - please use either Y or N for parameter &yncheck1. = &yncheck2.);
			%let end_kqtlfcomp = Y;
		%end;

		%*Stop macro if one of the parameters broke the rule;
		%if &end_kqtlfcomp = Y %then %goto endmac;
	%end;

	%local a lib nmemname;

	%*Retreive datasets;
	%do a = 1 %to 2;
		%if &a. = 1 %then %let lib = &prod_lib.;
		%if &a. = 2 %then %let lib = &qc_lib.;

		%let nmemname = 0;

		%if &a. = 2  %then %do;
			%if "&qc_output." = "" %then %do;
				proc sql noprint;
					select count(distinct memname), memname, lowcase(memname), memlabel into: nmemname, : memname, : qc_output, : memlabel&a. from dictionary.tables
						where libname = strip(upcase("&lib.")) and index(strip(upcase(reverse(memname))), strip(upcase(reverse("&output.")))) = 1;
				quit;
			%end;
			%else %do;
				%let nmemname = 1;
				%let memname = &qc_output.;
				%let qc_output = %sysfunc(lowcase(&qc_output.));
			%end;
		%end;

		%if &a. = 2 and &nmemname. > 1 %then %do;
			%put %sysfunc(compress(ERR OR:)) kqtlfcomp.sas - qc library &lib. did not contain a clear &output. dataset to take along;
			%goto endmac;
		%end;

		%if &a. = 1 %then %do;
			%if %sysfunc(exist(&lib..&output.)) = 0 %then %do;
				%put %sysfunc(compress(ERR OR:)) kqtlfcomp.sas - production file &lib..&output. did not exist;
				%goto endmac;
			%end;
		%end;
		%else %do;
			%if %sysfunc(exist(&lib..&memname.)) = 0 %then %do;
				%put %sysfunc(compress(ERR OR:)) kqtlfcomp.sas - qc file &lib..&output. did not exist;
				%goto endmac;
			%end;
		%end;

		%if "&prod_drop." ^= "" and &a. = 1 %then %do;
			%if %upcase(&dropchecked.) ^= Y %then %do;
				%put %sysfunc(compress(WARNIN G:)) kqtlfcomp.sas - vars: &prod_drop. dropped from the production dataset before comparing.;
				%put %sysfunc(compress(WARNIN G:)) kqtlfcomp.sas - please double check that this is correct. If so, put dropchecked = Y;
			%end;
			%else %if %upcase(&dropchecked.) = Y %then %do;
				%put %sysfunc(compress(INF O:)) vars: %sysfunc(compbl(&prod_drop.)) dropped from the production dataset before comparing.;
			%end;
			%local prod_drop1;
			%let prod_drop1 = %sysfunc(byte(34))%sysfunc(tranwrd(%upcase(%sysfunc(compbl(&prod_drop.))),%str( ),%str(" ")))%sysfunc(byte(34));
		%end;

		%*Select variables to remove label from;
		%local vars type;
		%let vars = ;
		%let type = num;

		proc sql noprint;
			select distinct name, type into: vars separated by " ", : type separated by " " from dictionary.columns where libname = upcase("&lib") 
				%if &a. = 1 %then %do;
					and memname = upcase("&output.")
				%end;
				%else %do;
					and memname = upcase("&memname.")
				%end;; 
		quit;
      
		%*Read in data, if need be remove unwanted layout differences;
		data %if &a. = 1 %then %do;
			prod_&output2.
			%if "&prod_drop." ^= "" %then %do;
				(drop = &prod_drop.)
			%end;
		%end;
		%else %do;
			qc_&output2.
		%end;;
		%if &a. = 1 %then %do;
			set &lib..&output.;
			where &where.;
		%end;
		%else %do;
			set &lib..&memname.;
			where &where.;
		%end;

		%local b;
		%if %upcase(&ignlbl.) = Y %then %do b = 1 %to %sysfunc(countc(&vars., %str( ))) + 1;
			label %scan(&vars., &b., %str( )) = ' ';
		%end;

		%if (%upcase(&ignspl.) = Y or %upcase(&ignspc.) = Y or %upcase(&compress.) = Y) and %index(&type., char) %then %do;

			array _comp_txt (*) _character_;

			do _comp_tlf_i = 1 to dim(_comp_txt);

				%*Remove RTF instructions indentations;
				if index(_comp_txt(_comp_tlf_i), "|R/RTF'\li") > 0 then do;
					_comp_txt(_comp_tlf_i) = strip(substr(left(tranwrd(_comp_txt(_comp_tlf_i), "|R/RTF'\li", "")), index(left(tranwrd(_comp_txt(_comp_tlf_i), "|R/RTF'\li","")), "'") + 1));
				end;
				%* RTF line breaks back to a normal break;
				if index(_comp_txt(_comp_tlf_i), "|n") > 0 then do;
					_comp_txt(_comp_tlf_i) = tranwrd(_comp_txt(_comp_tlf_i), "|n", "|");
				end;

				%if %upcase(&ignspl.) = Y %then %do;
					_comp_txt(_comp_tlf_i) = tranwrd(_comp_txt(_comp_tlf_i), "&chrspl.", " ");
				%end;
				%if %upcase(&ignspc.) = Y %then %do;
					if index(_comp_txt(_comp_tlf_i), "|R/RTF'\li") > 0 then do;
						_comp_txt(_comp_tlf_i) = strip(substr(left(tranwrd(_comp_txt(_comp_tlf_i), "|R/RTF'\li", "")), 2));
					end;
					_comp_txt(_comp_tlf_i) = strip(compbl(_comp_txt(_comp_tlf_i)));
				%end;
				%if %upcase(&compress.) = Y %then %do;
					_comp_txt(_comp_tlf_i) = compress(_comp_txt(_comp_tlf_i));
				%end;
			end; 
			drop _comp_tlf_i; 
		%end;

		%if %upcase(&ignfor.) = Y %then %do;
			format _all_;
		%end;

		%if %upcase(&ignifor.) = Y %then %do;
			informat _all_;
		%end;
		run;

		%local records1 records2;
		%let records&a. = 0;

		proc sql noprint;
			select nobs into: records&a. from dictionary.tables where libname = "WORK" and memname =
				%if &a. = 1 %then %do;
					strip(upcase("prod_&output2."))
				%end;
				%else %do;
					strip(upcase("qc_&output2."))
				%end;;
		quit;
	%end;

	%*Check for records;
	%if &records1. ^= &records2. %then %do;
		data dif_nobs;
			length _type_ $8 _sort_  _obs_ 8 level compare $255 _spec _prod _qc $255 _dif $255 occurance 8;
			_type_ = "DIF";
			_sort_ = 1;
			_obs_ = .;
			level = "Comparing dataset metadata";
			occurance = .;
			compare = "Records in dataset";
			_prod = "&records1.";
			_qc = "&records2.";
			_spec = "";            
			_dif = "FAIL";
			output;
		run;
	%end;
   
	%*Get contents of the datasets to be compared;
	%do a = 1 %to 2; 
		%if &a. = 1 %then %let lib = &prod_lib.;
		%if &a. = 2 %then %let lib = &qc_lib.;

		proc sql noprint;
			create table _meta_&a. as
				select libname, memname, name as name1, upcase(name) as name, type, length, varnum, label, format, informat from dictionary.columns where libname = "WORK" and memname =
					%if &a. = 1 %then %do;
						strip(upcase("prod_&output2."))
					%end;
					%else %do;
						strip(upcase("qc_&output2."))
					%end;
				order by name;
		quit;
	%end;

	%*1a: comparing dataset metadata - variables;
	data dif_var_ (keep = _type_--occurance);
		length _type_ $8 _sort_  _obs_ 8 level compare $255 _spec _prod _qc $255 _dif $255 occurance 8;
		merge %do a = 1 %to 2;
			_meta_&a. (keep = name in = a&a.)
		%end;;
		by name;

		_type_ = "DIF";
		level = "comparing variable metadata";
		occurance = .;

		if a1*a2 = 0 then do;
			_sort_ = 2;
			_obs_ = .;
			compare = "variable existence";
			if a1 then _prod = "exists in production, but not in qc: "||strip(name);
			if a2 then _qc = "exists in qc, but not in production: "||strip(name);
			_spec = "spec: "||strip(name);
			_dif = "";
			output dif_var_;
		end;
	run;

	%if %upcase(&ignln.) = Y %then %do;
		%let vars = type label format informat;
	%end;
	%else %do;
		%let vars = type length label format informat;
	%end;

	%local nvars vc;
	%let nvars = %eval(%sysfunc(countc(&vars., %str( ))) + 1);

	data dif_var_meta_ (keep = _type_ _sort_ level compare _spec _prod _qc _dif occurance);
		merge _meta_1 (keep = name type length varnum label format informat 
						rename=(type = type_prod
								length = length_prod
								varnum = varnum_prod
								label = label_prod
								format = format_prod
								informat = informat_prod) in = b)
			_meta_2 (keep = name type length varnum label format informat 
						rename=(type = type_qc 
								length = length_qc
								varnum = varnum_qc
								label = label_qc
								format = format_qc
								informat = informat_qc) in = c);
		by name;

		length _type_ $8 _sort_  _obs_ 8 level compare $255 _spec _prod _qc $255 _dif $255 occurance 8;

		_type_ = "DIF";
		_sort_ = 4;
		_obs_ = .;
		level = "comparing dataset metadata";
		occurance = .;
      
		%do vc = 1 %to &nvars.;
			compare = "%scan(&vars., &vc.)";

			%*Start comparison qc versus production;
			if b*c then do;
				if %scan(&vars., &vc.)_prod ^= %scan(&vars., &vc.)_qc then do;
				   _prod = tranwrd(vlabel(%scan(&vars., &vc.)_prod), 'Column', '')||" production:"||strip(vvalue(%scan(&vars., &vc.)_prod));
				   _qc = tranwrd(vlabel(%scan(&vars., &vc.)_qc), 'Column', '')||" qc:"||strip(vvalue(%scan(&vars., &vc.)_qc));
				   _spec = strip(name);
				   output; 
				end;
			end;
			_dif = "FAIL";
		%end;
	run;

	%put %str(INF)%str(O: kqtlfcomp: start comparing &output. VS qc &qc_output.);

	%*Check if there is something to compare;
	%if &records1. = 0 or &records2. = 0 %then %do;
		%if &records1. = 0 and &records2. = 0 %then %put %str(IN)%str(FO: No records found for output &output. in both production and qc. Please check.);
		%else %do;
			%if &records1. = 0 %then %put %str(ERR)%str(OR: kqtlfcomp.sas - no filled dataset found in library &prod_lib. for domain &output., or selection resulted in no records);
			%if &records2. = 0 %then %put %str(ERR)%str(OR: kqtlfcomp.sas - no filled dataset found in library &qc_lib for domain &output., or selection resulted in no records);
		%end;
		%goto compile;
	%end;

	title "Production &output. VS qc &qc_output.";
	proc compare data = prod_&output2. compare = qc_&output2.  out = _comp1 outdif outbase outcomp outnoeq %if &crit ^=  %then %do; criterion=&crit. %end;;
	run;
	title;

	%global check_compare_rc;
	%let check_compare_rc = &sysinfo.;

	data _null_;
		if substr(reverse(put(&check_compare_rc., binary16.)), 1, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Data set labels differ.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 2, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Data set types differ.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 3, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Variable has different informat.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 4, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Variable has different format.";
		%if %upcase(&ignln.) ^= Y %then %do;
			if substr(reverse(put(&check_compare_rc., binary16.)), 5, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Variable has different length." ;
		%end;
		if substr(reverse(put(&check_compare_rc., binary16.)), 6, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Variable has different label.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 7, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Base data set has observation not in comparison.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 8, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Comparison data set has observation not in base." ;
		if substr(reverse(put(&check_compare_rc., binary16.)), 9, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Base data set has BY group not in comparison.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 10, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Comparison data set has BY group not in base." ;
		if substr(reverse(put(&check_compare_rc., binary16.)), 11, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Base data set has variable not in comparison." ;
		if substr(reverse(put(&check_compare_rc., binary16.)), 12, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Comparison data set has variable not in base.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 13, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: A value comparison was unequal.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 14, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Conflicting variable types." ;
		if substr(reverse(put(&check_compare_rc., binary16.)), 15, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: BY variables do not match.";
		if substr(reverse(put(&check_compare_rc., binary16.)), 16, 1) = '1' then put "WARNIN" "G: kqtlfcomp.sas - &output. " "Proc Compare: Fata" "l erro" "r: comparison not done.";
	run;

	%local nobs;

	data _null_;
		if 0 then set _comp1 nobs = comp_tlf_obs;
		call symput('nobs', compress(put(comp_tlf_obs, best.)));
		stop;
	run;

	data _comp2 (drop = difr baser compr);
		%if &nobs. = 0 %then %do;
			length _type_ $8;
			_type_ = "BASE";
			_obs_ = 1;
			output;
			length _type_ $8;
			_type_ = "COMPARE";
			_obs_ = 1;
			output;
			length _type_ $8;
			_type_ = "DIF";
			_obs_ = 1;
			output;  
		%end;
		set _comp1 end = end;
		%if &nobs. = 0 %then %do;
			stop;
		%end;
		retain difr compr baser 0;
		if _type_ = "DIF" then difr = 1;
		if _type_ = "COMPARE" then compr = 1;
		if _type_ = "BASE" then baser = 1;
		output;  
		if end and difr = 0 then do;
			length _type_ $8;
			_type_ = "DIF";
			_obs_ = _obs_ + 1;
			output; 
		end;
		if end and compr = 0 then do;
			length _type_ $8;
			_type_ = "COMPARE";
			_obs_ = _obs_ + 1;
			output; 
		end;
		if end and baser = 0 then do;
			length _type_ $8;
			_type_ = "BASE";
			_obs_ = _obs_ + 1;
			output; 
		end;
	run;

	proc sort data = _comp2;
		by _obs_ _type_;
	run;

	proc transpose data = _comp2 out = _compchar1 (drop = _label_ where = (upcase(_name_) ^= "_TYPE_" and index(dif,'X') > 0 and dif ^= ''));
		by _obs_;
		var _character_;
		id _type_;
	run;

	data _compchar2 (drop = base compare dif rename = (base2 = base compare2 = compare dif2 = dif));
		length _name_ compare2 $255 base2 dif2 $200;
		set _compchar1;
		base2 = strip(base);
		compare2 = strip(compare);
		dif2 = strip(dif);
	run;

	proc transpose data = _comp2 out = _compnum1 (drop = _label_ where = (upcase(_name_) not in ("_OBS_") and (base ^= compare) and dif ^= .E));
		by _obs_;
		var _numeric_;
		id _type_;
	run;

	data _compnum2 (drop = base compare dif rename = (base2 = base compare2 = compare dif2 = dif));
		length _name_ compare2 $255 base2 dif2 $200;
		set _compnum1;
		base2 = strip(vvalue(base));
		compare2 = strip(vvalue(compare));
		dif2 = strip(vvalue(dif));
	run;

	data _comp_val2 (keep = _type_ _sort_ level compare _spec _prod _qc _dif _obs_);
		length _type_ $8 _sort_  _obs_ 8 level compare $255 _spec _prod _qc $255 _dif $255;
		set _compchar2
		    _compnum2;
		_type_ = "DIF";
		_sort_ = 11;
		level = "Variable Value comparison";
		_prod = base;
		_qc = compare;
		_spec = _name_;
		_dif = dif;
		compare = "Record "||strip(put(_obs_, best32.));
	run;

	proc sql noprint;
		create table dif_value as
			select *, count(1) as occurance from _comp_val2 group by _sort_,_spec;
	quit;

	%compile:

	proc sql noprint;
		select memname into: dif separated by " " from dictionary.tables where libname = "WORK" and substr(memname,1,4) = "DIF_";
	quit;

	data _finding1 (keep = _type_ _sort_ level compare _spec _prod _qc _dif occurance _obs_);
		set &dif.;
	run;

	proc sort data = _finding1 out = _finding2;
		by _sort_ _obs_ compare;
	run;

	data find_&output2 (drop = _obs_);
		length _type_ $8 _sort_ _obs_ 8 level compare $255 _spec _prod _qc $255 _dif $255 occurance 8.;
		set _finding2 end = end;
		by _sort_ _obs_ compare;
	run;

	%endmac:

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets lib = work nolist nodetails;
			delete dif: _comp: _finding1: _finding2: _meta:;
		run;
	%end;

 %mend kqtlfcomp;
