/************************************************************************************
* Program/Macro:             kdident.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      21OCT2021
* Program Title:             
*
* Description:               Macro for beautifully splitting character variables for output in table/listing
* Remarks:
* Input:                     &invar variable
* Output:                    &outvar variable
*
* Parameters:                invar - name of the input variable.
*			   				 outvar - name of the output variable.
*			   				 maxln - maximum number of character allowed per line.
*			   				 tabchar - tabulation characters, used to pad newlines.
*			   				 newlchar - newline character.
*			   				 debug - flag, that determines whether to delete temporary variables or not.
*
* Sample Call:               %kdident(aebodsys, 17);
*							 %kdident(lbcomm1, 32, outvar=col10, tabchar=%str());
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/

%macro kdident(invar /*Required. Name of the input variable.*/,
			   maxln /*Required. Maximum number of character allowed per line.*/,
			   outvar=&invar._new /*Default: &invar._new. Name of the output variable.*/,
			   tabchar=%str($ $ $ ) /*Default: %str($ $ $ ). Tabulation characters, used to pad newlines.*/,
			   newlchar=%str($n) /*Default: %str($n). Newline character.*/,
			   debug=N /*Default: N. If N then deletes temporary variables.*/);

	%local end_kdident params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_kdident = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = invar maxln outvar;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: kdident.sas - &param_name. is required parameter and should not be NULL);
			%let end_kdident = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_kdident. = Y %then %goto endmac;

	if length(&invar.) >= 10000 then put "WAR" "NING: kdident.sas - input variable length is more significant than 10000. Need to update macro conditions";
	
	length &outvar. $10000 __tmp_&invar.l1-__tmp_&invar.l1000 8;
	%*Array of debug variables, will store position of the new line (should be right after newline character and tabs);
	array __tmp_&invar.ls {*} __tmp_&invar.l1-__tmp_&invar.l1000;
	&outvar. = strip(scan(&invar., 1, " "));

	if not missing(&invar.) then do __tmp_i = 2 to countw(&invar., " ");
		%*Calculate length of the last line (part of string after last $newline symbol);
		__tmp_pos_arr = find(&outvar., "&newlchar.&tabchar.", "", -10000);

		%*If there are no newline characters, find will return 0 - change it for 1 to avoid log messages in SUBSTR FUNCTION;
		if __tmp_pos_arr <= 0 then __tmp_pos_arr = 1;
		%*If newline chars are found, add length of newline + tab characters to __tmp_pos_arr (it stores coordinate of 1st character from new line);
		else __tmp_pos_arr = __tmp_pos_arr + lengthc("&newlchar.&tabchar.");

		__tmp_&invar.ls[__tmp_i-1] = __tmp_pos_arr;

		%*Check if adding another word will hit the symbol limit for string and put the new word on a new line if it does;
		if length(strip(&outvar.)) + length(strip(scan(&invar., __tmp_i, " "))) + 1 > &maxln. and
			length(strip(substr(&outvar., __tmp_pos_arr))) + lengthc("&tabchar.")/2 + length(strip(scan(&invar., __tmp_i, " "))) > &maxln. then &outvar. = strip(&outvar.)||"&newlchar.&tabchar."||strip(scan(&invar., __tmp_i, " "));
		%*Leave it at the current line if it does not exceed max line length;
		else &outvar. = strip(&outvar.)||" "||strip(scan(&invar., __tmp_i, " "));
	end;

	%*Delete/keep temporary variables for debug purposes;
	%if &debug. = N %then %do;
		drop __tmp_:;
	%end;

	%endmac:

%mend kdident;
