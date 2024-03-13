/************************************************************************************
* Program/Macro:             xucont.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Oleksandr Homel
* Date:                      12AUG2022
* Program Title:             
*
* Description:               Macro which executes contents procedure.
* Remarks:
* Input:                     &inds dataset from &sourcelib
* Output:                    contents procedure of &inds
*
* Parameters:                inds - name(s) of the input dataset(s).
*							 sourcelib - name of the input library.
*							 contopts - options for the contents procedure.
*                            
* Sample Call:               %xucont(dm suppdm, sdtm);
*							 %xucont(adsl, adam);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro xucont(inds /*Required. Name(s) of the input dataset(s).*/,
			  sourcelib /*Required. Name of the input library.*/,
			  contopts=varnum /*Default: varnum. Options for the contents procedure.*/);

	%local end_xucont params_to_check i param_name param_value nwrd wrd;

	%*Flag for premature macro termination;
	%let end_xucont = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = inds sourcelib;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xucont.sas - &param_name. is required parameter and should not be NULL);
			%let end_xucont = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xucont. = Y %then %goto endmac;

	%*Count number of datasets specified in INDS parameter;
	%let nwrd = %sysfunc(countw(&inds.));

	%*Loop to process each dataset name;
	%do i = 1 %to &nwrd.;
		%*Put dataset name into the macro variable;
		%let wrd = %scan(&inds., &i.);

		%*Check if dataset is present in library;
		%if %sysfunc(exist(&sourcelib..&wrd.)) = 0 %then %do;
			%put %str(ERR)%str(OR: xucont.sas - dataset %upcase(&wrd.) was not found in %upcase(&sourcelib.) library);
		%end;
		%else %do;
			%*Execute contents procedure;
			proc contents data=&sourcelib..&wrd. &contopts.;
			run;
		%end;
	%end;

	%endmac:

%mend xucont;