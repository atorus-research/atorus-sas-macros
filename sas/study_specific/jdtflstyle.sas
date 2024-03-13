/************************************************************************************
* Program/Macro:             jdtflstyle.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Rostyslav Didenko
* Date:                      05MAY2021
* Program Title:             
*
* Description:               A style template macro for study PDF/RTF outputs. Opens
*                            ODS PDF/RTF destination and creates PDF/RTF file. Also, creates
*							 global macro variables with timestamps.
*                            See arcticle https://support.sas.com/resources/papers/proceedings/proceedings/forum2007/225-2007.pdf
*                            for more details on ODS style, markup and tagsets.
* Remarks:
* Input:                     N/A
* Output:                    &filename.rtf/&filename.pdf in &filepath, &timestamp &tmstmp_date &tmstmp_time global macro variables
*
* Parameters:                filename - name of the output file.
*							 filepath - file save path
*                            type - file extension. RTF/PDF.
*							 lmarg - left margin size.
*							 rmarg - right margin size.
*							 tmarg - top margin size.
*							 bmarg - bottom margin size.
*							 escapechar - escape character.
*                            
* Sample Call:               %jdtflstyle(T_10_1_1);
*							 %jdtflstyle(F_15_1_2, bmarg=0.8in);
*
* Assumptions:               
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
* #1			A.Homel						   17FEB2022		   NOGTITLE and NOGFOOTNOTE options added to prevent titles and
*																   footnotes from appearing in graphical output.
* #2			A.Homel						   12AUG2022		   Macro renamed jstflstyle -> jdtflstyle. Cosmetics updated.
*																   filename, filepath, lmarg, rmarg, tmarg, bmarg, escapechar parameters
*																   added. Parameter emptiness check added.
************************************************************************************/

%macro jdtflstyle(filename /*Required. Name of the output file.*/,
				  filepath=&__root.&__clnt_I.&II.&__comp.&II.&__prot.&__subfolders_I.&II.&__task.&II.&__level.&__side_I.&II.tfl /*Default: side/tlf. File save path.*/,
	              type=RTF /*Default: RTF. File extension. RTF/PDF.*/,
				  lmarg=1in /*Default: 1in. Left margin size.*/,
				  rmarg=1in /*Default: 1in. Right margin size.*/,
				  tmarg=0.5in /*Default: 0.5in. Top margin size.*/,
				  bmarg=1in /*Default: 1in. Bottom margin size.*/,
				  escapechar=$ /*Default: $. Escape character.*/);

	%local end_jdtflstyle params_to_check i param_name param_value;

	%*Flag for premature macro termination;
	%let end_jdtflstyle = N;

	%*Define required parameter names that should be checked whether they are empty;
	%let params_to_check = filename filepath type lmarg rmarg tmarg bmarg escapechar;

	%*Macro parameter checks;
	%*Iterate through parameters;
	%do i = 1 %to %sysfunc(countw(&params_to_check., %str( )));
		%*Sub-select macro name;
		%let param_name = %scan(&params_to_check., &i., %str( ));

		%*Sub-select macro value;
		%let param_value = &%scan(&params_to_check., &i., %str( )).;

		%*Check whether required parameters are empty;
		%if %length(&param_value.) = 0 %then %do;
			%put %str(ERR)%str(OR: jdtflstyle.sas - &param_name. is required parameter and should not be NULL);
			%let end_jdtflstyle = Y;
		%end;
		%else %do;
			%if %lowcase(&param_name.) = type %then %do;
				%if %lowcase(&param_value.) ^= rtf and %lowcase(&param_value.) ^= pdf %then %do;
					%put %str(ERR)%str(OR: jdtflstyle.sas - parameter &param_name. should be RTF or PDF);
					%let end_jdtflstyle = Y;
				%end;
			%end;
		%end;
	%end;

	%*Stop macro if one of the parameters broke the requirements;
	%if &end_jdtflstyle. = Y %then %goto endmac;

	ods path(prepend) work.templat(update);

	%*Define styles;
	proc template;
		define style glst1;
			class body, data /
				fontfamily=courier
				fontsize=9pt
				backgroundcolor=white
				color=black;

			class header /
				fontfamily=courier
				fontweight = medium
				fontsize=9pt
				backgroundcolor=white
				color=black;

			style table /
				fontweight = medium
				fontstyle = roman
				color = black
				backgroundcolor = white
				borderspacing = 1
				cellpadding = 2;

			style header /
				fontfamily = courier
				fontsize = 9pt
				fontweight = medium
				fontstyle = roman
				color = black
				backgroundcolor = white
				bordertopcolor=black
				bordertopwidth=1
				borderbottomcolor=black
				borderbottomwidth=1
				borderspacing = 1
				cellpadding = 7;

			style systemtitle /
				fontfamily = courier
				fontsize = 9pt
				fontweight = medium;

			style systemfooter /
				fontfamily = courier
				fontsize = 9pt
				fontweight = medium;
		end;
	run;

	%*Create macro variables with timestamps;
	%global timestamp tmstmp_date tmstmp_time;

	%let timestamp = %sysfunc(datetime(), e8601dt16.);
	%let tmstmp_date = %scan(&timestamp, 1, T);
	%let tmstmp_time = %scan(&timestamp, 2, T);;

	%*Open output destination;
	ods _all_ close;
	options orientation = landscape device = ACTXIMG nodate nonumber leftmargin = &lmarg. rightmargin = &rmarg. topmargin = &tmarg. bottommargin = &bmarg.;
	title; footnote;

	%if %lowcase(&type.) = pdf %then %do;
		ods pdf file = "%sysfunc(compress(&filepath.&II.&filename..pdf))" style = glst1 nogtitle nogfootnote nobookmarkgen;
	%end;
	%if %lowcase(&type.) = rtf %then %do;
		ods rtf file = "%sysfunc(compress(&filepath.&II.&filename..rtf))" style = glst1 nogtitle nogfootnote nobodytitle;
	%end;

	ods escapechar = "&escapechar.";

	%endmac:

%mend jdtflstyle;