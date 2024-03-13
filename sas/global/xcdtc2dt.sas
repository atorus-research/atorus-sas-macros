/************************************************************************************
* Program/Macro:             xcdtc2dt.sas
* Protocol:
* SAS Ver:                   SAS 9.4 V9
* Author:					 Rostyslav Didenko
* Date:						 19FEB2021
* Program Title:             
*
* Description:               Convert character --DTC variable into analysis -DT -TM -DTM. Also
*                            creates analysis -DY variable.
* Remarks:
* Input:					 &dtcdate variable and &refdate variable if specified
* Output:					 &prefix.dtm, &prefix.dt, &prefix.tm variables, and &prefix.dy variable if &refdate is specified
*
* Parameters:                dtcdate - name of --DTC variable.
*                            prefix - prefix for numeric analysis date.
*                            refdate - numeric reference date.
*
* Sample Call:               %xcdtc2dt(aestdtc, prefix=ast, refdate=trtsdt);
*
* Assumptions:
* Revisions:
* Revision #    Programmer                     Date                Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* #1            A. Homel					   17FEB2022		   Relative day now calculated only if both dates are non-missing.
* #2			A. Homel					   29JUL2022		   Parameter emptiness check added. Cosmetics updated.
************************************************************************************/

%macro xcdtc2dt(dtcdate /*Required. Name of --DTC variable.*/,
                prefix=a /*Default: a. Prefix for numeric -DT -TM -DTM -DY analysis variables.*/,
                refdate= /*Optional. Reference numeric date.*/);

	%local end_xcdtc2dt params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_xcdtc2dt = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = dtcdate;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xcdtc2dt.sas - &param_name. is required parameter and should not be NULL);
			%let end_xcdtc2dt = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xcdtc2dt. = Y %then %goto endmac;

	%*Handle date without time or date with partial time.;
	if 10 <= length(strip(&dtcdate.)) < 16 then %upcase(&prefix.dt) = input(substr(strip(&dtcdate.), 1, 10), e8601da.);
	%*Handle date with time.;
	else if length(strip(&dtcdate.)) = 16 or length(strip(&dtcdate.)) = 19 then do;
		%upcase(&prefix.dtm) = input(strip(&dtcdate.), e8601dt.);
		%upcase(&prefix.dt) = datepart(&prefix.dtm);
		%upcase(&prefix.tm) = timepart(&prefix.dtm);
	end;
      
	%*Calculate relative analysis day only if both analysis dates are non-missing.;
    %if &refdate. ^= %then %do;
        if nmiss(&prefix.dt, &refdate.) = 0 then %upcase(&prefix.dy) = &prefix.dt - &refdate. + (&prefix.dt >= &refdate.);
    %end;

	%endmac:

%mend xcdtc2dt;
