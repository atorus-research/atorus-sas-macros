/************************************************************************************
* Program/Macro:             xumrgcs.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksandr Homel
* Date:                      22AUG2022
* Program Title:             
*
* Description:               Macro which merges SUPP-- and CO to the input SDTM dataset
* Remarks:
* Input:                     &inds input dataset(s) from &sourcelib library
* Output:                    &inds_supp_co dataset(s)
*
* Parameters:                inds - name(s) of the input dataset(s).
*							 sourcelib - name of the input library.
*							 supp - flag, that determines whether to merge SUPP-- dataset or not.
*							 co - flag, that determines whether to merge CO dataset or not.
*							 debug - flag, that determines whether to delete temporary datasets or not.
*                            
* Sample Call:               %xumrgcs(dm ae, sdtm, supp=Y, co=N);
*							 %xumrgcs(pr, sdtm, supp=Y, co=Y);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* 
************************************************************************************/

%macro xumrgcs(inds /*Required. Name(s) of the input dataset(s).*/,
			   sourcelib /*Required. Name of the input library.*/,
			   supp=Y /*Default: Y. If Y then merge SUPP-- dataset.*/,
			   co=Y /*Default: Y. If Y then merge CO dataset.*/,
			   debug=N /*Default: N. If N then delete temporary datasets.*/);

	%local end_xumrgcs params_to_check i param_name param_value wrd dmnname outname;

	%*Flag for premature macro termination;
	%let end_xumrgcs = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds sourcelib supp co;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xumrgcs.sas - &param_name. is required parameter and should not be NULL);
			%let end_xumrgcs = Y;
		%end;
		%else %do;
			%*Check whether supp parameter has expected values;
			%if %lowcase(&param_name.) = supp %then %do;
				%if %lowcase(&param_value.) ^= y and %lowcase(&param_value.) ^= n %then %do;
					%put %str(ERR)%str(OR: xumrgcs.sas - parameter &param_name. should be Y or N);
					%let end_xumrgcs = Y;
				%end;
			%end;
			%if %lowcase(&param_name.) = co %then %do;
				%if %lowcase(&param_value.) ^= y and %lowcase(&param_value.) ^= n %then %do;
					%put %str(ERR)%str(OR: xumrgcs.sas - parameter &param_name. should be Y or N);
					%let end_xumrgcs = Y;
				%end;
			%end;
		%end;
	%end;

	%if %lowcase(&supp.) = n and %lowcase(&co.) = n %then %do;
		%put %str(ERR)%str(OR: xumrgcs.sas - both parameters supp and co cannot be specified as N);
		%let end_xumrgcs = Y;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xumrgcs. = Y %then %goto endmac;

	%*Loop to process each dataset name;
	%do i = 1 %to %sysfunc(countw(&inds.));
		
		%*Put dataset name into the macro variable;
		%let wrd = %scan(&inds., &i.);

		%let outname = &wrd.;

		%if %sysfunc(exist(&sourcelib..&wrd.)) %then %do;
			proc sql noprint;
				%*Get domain name from input dataset;
				select distinct domain into: dmnname from &sourcelib..&wrd.;
			quit;

			%if %lowcase(&supp.) = y %then %do;
				%if %sysfunc(exist(&sourcelib..supp&wrd.)) %then %do;

					%local sidvar sdsetnum svarnum sidtype src;

					%let outname = &outname._supp;
					%let sidvar = ;

					proc sql noprint;
						%*Get id variable name from SUPP--;
						select distinct idvar into: sidvar from &sourcelib..supp&wrd.;
					quit;

					%*Get type of the id variable in the dataset;
					%if &sidvar. ^= %then %do;
						%let sdsetnum = %sysfunc(open(&sourcelib..&wrd.));
						%let svarnum = %sysfunc(varnum(&sdsetnum., &sidvar.));
						%let sidtype = %sysfunc(vartype(&sdsetnum., &svarnum.));
						%let src = %sysfunc(close(&sdsetnum.));
					%end;
					%else %do;
						%let sidtype = ;
					%end;

					%*Transpose SUPP--;
					proc sort data = &sourcelib..supp&wrd. out = __tmp_&sysmacroname._&wrd._s1;
						by usubjid idvar idvarval;
					run;

					proc transpose data = __tmp_&sysmacroname._&wrd._s1 out = __tmp_&sysmacroname._&wrd._s2(drop = _:);
						by usubjid idvar idvarval;
						id qnam;
						var qval;
					run;

					%*Change id variable type for merge if needed;
					data __tmp_&sysmacroname._&wrd._s3(drop = idvar idvarval);
						set __tmp_&sysmacroname._&wrd._s2;

						%if %lowcase(&sidtype.) = c %then %do;
							&sidvar. = strip(idvarval);
						%end;
						%if %lowcase(&sidtype.) = n %then %do;
							&sidvar. = input(strip(idvarval), best.);
						%end;
					run;

					proc sort data = __tmp_&sysmacroname._&wrd._s3;
						by usubjid &sidvar.;
					run;

					proc sort data = &sourcelib..&wrd. out = __tmp_&sysmacroname._&wrd._s4;
						by usubjid &sidvar.;
					run;

					%*Merge SUPP--;
					data __tmp_&sysmacroname._&wrd. %if %lowcase(&co.) = y %then %do; __tmp_&sysmacroname._&wrd._s5 %end;;
						merge __tmp_&sysmacroname._&wrd._s4(in = a) __tmp_&sysmacroname._&wrd._s3;
						by usubjid &sidvar.;
						if a;
					run;
				%end;
				%else %do;
					%put %str(ERR)%str(OR: xumrgcs.sas - %upcase(supp&wrd.) was not found in %upcase(&sourcelib.) library);
				%end;
			%end;
			%if %lowcase(&co.) = y %then %do;
				%if %sysfunc(exist(&sourcelib..co)) %then %do;

					%local cnobs cidvar cdsetnum cvarnum cidtype crc;

					%let outname = &outname._co;
					%let cidvar =;

					proc sql noprint;
						%*Get id variable name from CO;
						select distinct idvar into: cidvar from &sourcelib..co
						where lowcase(rdomain) = lowcase("&dmnname.");
						
						%*Count number of comment observations for the dataset;
						select count(*) into: cnobs from &sourcelib..co
						where lowcase(rdomain) = lowcase("&dmnname.");
					quit;

					%if &cnobs. = 0 %then %do;
						%put %str(NO)%str(TE: xumrgcs.sas - CO has no comments for %upcase(&wrd.) domain);
					%end;

					%*Get type of the id variable in the dataset;
					%if &cidvar. ^= %then %do;
						%let cdsetnum = %sysfunc(open(&sourcelib..&wrd.));
						%let cvarnum = %sysfunc(varnum(&cdsetnum., &cidvar.));
						%let cidtype = %sysfunc(vartype(&cdsetnum., &cvarnum.));
						%let crc = %sysfunc(close(&cdsetnum.));
					%end;
					%else %do;
						%let cidtype = ;
					%end;

					%*Change id variable type for merge if needed;
					data __tmp_&sysmacroname._&wrd._c1(keep = usubjid &cidvar. coval:);
						set &sourcelib..co(where = (lowcase(rdomain) = lowcase("&dmnname.")));

						%if %lowcase(&cidtype.) = c %then %do;
							&cidvar. = strip(idvarval);
						%end;
						%if %lowcase(&cidtype.) = n %then %do;
							&cidvar. = input(strip(idvarval), best.);
						%end;
					run;

					%*If the dataset with merged SUPP-- exists then add CO variables there;
					%if %sysfunc(exist(work.__tmp_&sysmacroname._&wrd.)) %then %do;
						proc sort data = __tmp_&sysmacroname._&wrd.;
							by usubjid &cidvar.;
						run;

						proc sort data = __tmp_&sysmacroname._&wrd._c1;
							by usubjid &cidvar.;
						run;

						%*Merge CO;
						data __tmp_&sysmacroname._&wrd.;
							merge __tmp_&sysmacroname._&wrd.(in = a) __tmp_&sysmacroname._&wrd._c1;
							by usubjid &cidvar.;
							if a;
						run;
					%end;
					%*Otherwise, merge to original dataset;
					%else %do;
						proc sort data = __tmp_&sysmacroname._&wrd._c1;
							by usubjid &cidvar.;
						run;

						proc sort data = &sourcelib..&wrd. out = __tmp_&sysmacroname._&wrd._c2;
							by usubjid &cidvar.;
						run;

						%*Merge CO;
						data __tmp_&sysmacroname._&wrd.;
							merge __tmp_&sysmacroname._&wrd._c2(in = a) __tmp_&sysmacroname._&wrd._c1;
							by usubjid &cidvar.;
							if a;
						run;
					%end;
				%end;
				%else %do;
					%put %str(ERR)%str(OR: xumrgcs.sas - CO was not found in %upcase(&sourcelib.) library);
				%end;
			%end;
			%if %sysfunc(exist(work.__tmp_&sysmacroname._&wrd.)) %then %do;
				data &outname.;
					set __tmp_&sysmacroname._&wrd.;
				run;

				proc datasets nolist nodetails lib = work;
					delete __tmp_&sysmacroname._&wrd.;
				run;
			%end;
			%else %do;
				data &outname.;
					set &sourcelib..&wrd.;
				run;
			%end;
		%end;
		%else %do;
			%put %str(ERR)%str(OR: xumrgcs.sas - %upcase(&wrd.) was not found in %upcase(&sourcelib.) library);
		%end;
	%end;

	%*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
	    proc datasets nolist nodetails lib = work;
			delete __tmp_&sysmacroname.:;
		run;
	%end;

	%endmac:

%mend xumrgcs;