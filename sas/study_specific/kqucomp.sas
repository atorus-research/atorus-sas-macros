/************************************************************************************
* Program/Macro:             kqucomp.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Alex Khylko
* Date:                      20Aug2021
* Program Title:             
*
* Description:               Macro which compares the datasets.
* Remarks:
* Input:                     
* Output:                    
* Parameters:                base - name of the dataset which is used as base in compare procedure.
*							 qc - prefix of the qc dataset name.
*							 id - list of id variables.
*							 prod_lib - name of the library from which base dataset is uploaded.
*							 qc_lib - name of the library from which qc dataset is uploaded.
*							 crit - criterion for the compare procedure, if needed.
*							 supp - flag, that determines whether to compare SUPP-- dataset, or not.
*							 com - flag, that determines whether to compare comments dataset, or not.
*                            
* Sample Call:               %kqucomp(base = DM, prod_lib = sdtm, supp = Y, com = Y);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
*
* ----------    ----------------------         ------------        ---------------------------
* #1			Oleksii Mikriukov			   6AUG2022			   Removed sorting before compare to catch incorrect order
*																   Added qc_lib parameter
*																   Compare supp/comm datasets if at least one side (prod or qc) has records in dataset
*																   Check required parameters emptiness
************************************************************************************/

%macro kqucomp(base=&domain. /*Default: &domain. Name of the dataset which is used as base in compare procedure.*/,
			   qc=qc /*Default: qc. Prefix of the qc dataset name.*/,
			   id=&&&domain.sortstring /*Default: &&&domain.sortstring. List of id variables.*/,
			   prod_lib=sdtm /*Default: sdtm. Name of the library from which base dataset is uploaded.*/,
			   qc_lib=work /*Default: work. Name of the library from which qc dataset is uploaded.*/,
			   crit= /*Optional. Specify the criterion for the compare procedure.*/,
			   supp=N /*Default: N. Compare the SUPP-- dataset, or not.*/,
			   com=N /*Default: N. Compare the comments dataset, or not.*/);

	%local end_kqucomp i params_to_check param_name param_value;

	%*Flag for premature macro termination;
	%let end_kqucomp = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = base prod_lib qc_lib;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( ));

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: kqucomp.sas - &param_name. is required parameter and should not be NULL);
			%let end_kqucomp = Y;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_kqucomp. = Y %then %goto endmac;

	proc contents data = &prod_lib..&base.;
	run;

	%*Compare procedure.;
	proc compare data = &prod_lib..&base. comp = &qc_lib..&qc.&domain. listall %if &crit ^=  %then %do; criterion = &crit. %end;; 
		%if &id. ^= %then %do; id &id.; %end;
	run;

	%*Compare SUPP-- if needed.;
	%if %lowcase(&supp.) = y %then %do;

		%local nobs1_supp nobs2_supp;

		%*Check number of observations in both SUPP-- datasets.;
		proc sql noprint;
			select count(*) into:nobs1_supp
				from &prod_lib..supp&base.;
	 
			select count(*) into:nobs2_supp
				from &qc_lib..&qc.supp&domain.;
		quit;

		%*Execute compare procedure only if SUPP-- dataset is not empty.;
		%if &nobs1_supp. ne 0 or &nobs2_supp. ne 0 %then %do;
			proc contents data = &prod_lib..supp&base.;
			run;

			proc compare data = &prod_lib..supp&base. comp = &qc_lib..&qc.supp&domain. listall; 
				id studyid usubjid idvar idvarval qnam;
			run;
		%end;
	%end;

	%*Compare comments dataset if needed.;
	%if %lowcase(&com.) = y %then %do;

		%local nobs1_comm nobs2_comm;

		%*Check number of observations in both comments datasets.;
		proc sql noprint;
			select count(*) into:nobs1_comm
				from &prod_lib..&base._comm;
	 
			select count(*) into:nobs2_comm
				from &qc_lib..&qc.&base._comm;
		quit;

		%*Execute compare procedure only if comments dataset is not empty.;
		%if &nobs1_comm. ne 0 or &nobs2_comm. ne 0 %then %do;
			proc contents data = &prod_lib..&base._comm;
			run;

			proc compare data = &prod_lib..&base._comm comp = &qc_lib..&qc.&base._comm listall; 
				id studyid usubjid idvar idvarval ;
			run;
		%end;
	%end;

	%endmac:

%mend;