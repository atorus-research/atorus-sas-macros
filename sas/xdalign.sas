/************************************************************************************
* Program/Macro:             xdalign.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Rostyslav Didenko
* Date:                      05MAY2021
* Program Title:             
*
* Description:               Macro to do proper numbers allignment in PDF or RTF: period
*                            under period (decimal alignment).
* Remarks:
* Input:                     &invar variable
* Output:                    &invar variable with alignment
*
* Parameters:                invar - input variable name.
*                            type - type of the output, extension.
* 							 escapechar - escape character.
*                            len - length of the whole variable in the output, including indentation.
*
* Sample Call:               %xdalign(trt_1, type=PDF, len=6);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* #1			Oleksii Mikryukov			   14JUL2022		   Use a "." as the delimiter that separates 
*																   words to allign properly negative numbers
* #2			Oleksii Mikryukov			   03NOV2022		   Added escapechar parameter
************************************************************************************/

%macro xdalign(invar /*Required. Input variable name.*/,
               type=RTF, /*Default: RTF. Type of the output, extension.*/
			   escapechar=$ /*Default: $. Escape character.*/,
               len=6 /*Default: 6. Length of the whole variable in the output, including indentation.*/);

	%local end_xdalign params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_xdalign = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = invar type len;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xdalign.sas - &param_name. is required parameter and should not be NULL);
			%let end_xdalign = Y;
		%end;
		%else %if %lowcase(&param_name.) = type and %lowcase(&param_value.) ^= pdf and %lowcase(&param_value.) ^= rtf %then %do;
			%put %str(ERR)%str(OR: xdalign.sas - alligning not defined for &type. output type);
			%let end_xdalign = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xdalign. = Y %then %goto endmac;

    %*Add spaces for PDF outputs;
    %if %lowcase(&type.) = pdf %then %do;
        if length(scan(&invar., 1, ".")) = 1 then &invar. = "&escapechar.{nbspace %eval(&len. - 1)}" || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 2 then &invar. = "&escapechar.{nbspace %eval(&len. - 2)}" || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 3 then &invar. = "&escapechar.{nbspace %eval(&len. - 3)}" || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 4 then &invar. = "&escapechar.{nbspace %eval(&len. - 4)}" || strip(&invar.);
		else if length(scan(&invar., 1, ".")) = 5 then &invar. = "&escapechar.{nbspace %eval(&len. - 5)}" || strip(&invar.);
		else if length(scan(&invar., 1, ".")) > 5 then put "WARN" "ING: xdalign.sas - interger part is too long. Need to update macro conditions";
    %end;
    %*Add spaces for RTF outputs;
    %else %if %lowcase(&type.) = rtf %then %do;
        if length(scan(&invar., 1, ".")) = 1 then &invar. = repeat("&escapechar. ", %eval(&len. - 2)) || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 2 then &invar. = repeat("&escapechar. ", %eval(&len. - 3)) || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 3 then &invar. = repeat("&escapechar. ", %eval(&len. - 4)) || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 4 then &invar. = repeat("&escapechar. ", %eval(&len. - 5)) || strip(&invar.);
        else if length(scan(&invar., 1, ".")) = 5 then &invar. = repeat("&escapechar. ", %eval(&len. - 6)) || strip(&invar.);
		else if length(scan(&invar., 1, ".")) > 5 then put "WARN" "ING: xdalign.sas - interger part is too long. Need to update macro conditions";
    %end;

	%endmac:

%mend xdalign;