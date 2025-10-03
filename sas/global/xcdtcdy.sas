/**
* @file xcdtcdy.sas
* @brief Take two SDTM character --DTC dates and calculate SDTM --DY variable
*
* @author Atorus Research
* @date 19FEB2021
*
* @param[in] dtcdate Date to calculate --DY for (Required)
* @param[in] refdate Reference character date (Required)
*
* @return --DY numeric variable
*
* @par Example:
* @code
* %xcdtcdy(exstdtc, rfstdtc);
* %xcdtcdy(lbdtc, rfstdtc);
* @endcode
*
* @see N/A
*/

%macro xcdtcdy(dtcdate /*Required. Name of character --DTC variable to calculate --DY for.*/,
               refdate /*Required. Reference character date.*/);

	%local end_xcdtcdy params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_xcdtcdy = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = dtcdate refdate;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: xcdtcdy.sas - &param_name. is required parameter and should not be NULL);
			%let end_xcdtcdy = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_xcdtcdy. = Y %then %goto endmac;

    %*Check if dates have invalid characters;
	if prxmatch("/[a-zA-SU-Z]/", &dtcdate.) or prxmatch("/[a-zA-SU-Z]/", &refdate.) then put "ERR" "OR: xcdtcdy.sas - invalid argument value: dtcdate=" &dtcdate. "refdate=" &refdate.;
    else if length(&dtcdate.) >= 10 and length(&refdate.) >= 10 then do;
        %*Calculate  --DY variables;
		%upcase(%substr(%cmpres(&dtcdate.), 1, %length(%cmpres(&dtcdate.)) - 3))DY = input(substr(&dtcdate., 1 , 10), e8601da.) - input(substr(&refdate., 1, 10), e8601da.) + (input(substr(&dtcdate., 1, 10), e8601da.) >= input(substr(&refdate., 1, 10), e8601da.));
    end;

	%endmac:

%mend xcdtcdy;