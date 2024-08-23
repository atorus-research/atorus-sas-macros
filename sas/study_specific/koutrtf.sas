/************************************************************************************
* Program/Macro:             koutrtf.sas
* Protocol:                  
* SAS Ver:                   SAS 9.4 V9
* Author:                    Atorus Research
* Date:                      02Jan2024
* Program Title:             
*
* Description:               Macro which generates Table/Listing RTF out of final dataset.
* Remarks:
* Input:                     Final Table/Listing dataset
* Output:                    &oid.rtf
*
* Parameters:                inds=            Input dataset name. 
*                                             Default value: macro variable value &_oid (assuming there is a mechanism in place to create one).
*                            sortby=,         Additional sorting of dataset prior to generating an output. 
*                                             Value DATA results in no sorting. 
*                                             Default: data.
*                            byvar=,          BY variable printed in output subtitle and causing a page break. 
*                                             Missing value means no BY variable.
*                            byformat=,       If BYVAR is used, BYFORMAT should contain text format name to be applied.
*                            colwd=,          List of width of columns as a percentage of total page width, i.e: 24 25 30 20. 
*                                             Value AUTO will assign automatically calculated equal width. 
*                                             Default: AUTO
*                            headalign=,      Alignment of columns headers in form of list, i.e. L L C R.
*                                             L = Left, C = Center, R = Right. 
*                            bodyalign=,      Alignment of columns contents in form of list, i.e. L L C R.
*                                             L = Left, C = Center, R = Right. 
*                            leftgr=,         Number of columns nested and grouped starting from left side. Default = 0.
*                            escapechar=,     ODS Escape Character. Default = ^.
*                            MaxPageDigits=,  Number of digits in the last page, i.e. outputs having 300 pages should have value = 3.
*                                             Variable is used for proper positioning of Page X of Y footnote. Default: 1
*                            nblines=,        Number of data rows to be printed per page. Default = 17.
*                            nblineslist=,    Alternative way to specify number of data rows to print per page in form of list.
*                                             I.e. value = 10 15 20 would cause 10 rows printed on page 1, 15 rows on page 2 and 20 rows on page 3.
*                                             If value is provided, then it overrides NBLINES parameter.
*                            grpcont=,        Enables printing '(cont.)' text for grouping variables in case they were split in several pages.
*                                             Possible values: Y. Default: missing.
*                            spanhead=,       Optional parameter for printing spanning headeer (i.e. grouping headers). If chosen to use, it will replace automatically generated 
*                                             COLUMN statement in PROC REPORT and would require user input, i.e.: v1 ("Treatment 1_$_" v2 v3) ("Treatment 2_$_" v4 v5)
*                                             Adding _$_ in the end of each spanning header will apply standard styling for it.
*                                             Default: missing.
*                            splitchar=,      Character that is used to split headers/body into multiple lines.
*                                             Default: /
*                            wrap=,           Option to wrap infinished SOC/ATC to next page. Set to Y to enable.
*                                             Default: missing.
*                            debug=N          Enables saving interim datasets in the work directory for debugging purpose. 
*                                             Possible values: Y/N. Default: N.
*                            
* Sample Call:     %koutrtf (
*                            colwd          = 24 25 25 25,
*                            headalign      = l c c c,
*                            bodyalign      = l c c c,
*                            leftgr         = 1,
*                            byvar          = v0,
*                            byformat       = grpn
*                            maxpagedigits  = 1,
*                            grpcont        = Y,
*                            panhead       = v1 ("Treatment 1_$_" v2 v3) ("Treatment 2_$_" v4 v5),
*                            nblineslist    = 12 12 18 6 12 12
*                            );
*                            
*                  %koutrtf (
*                            inds           = final,
*                            type           = L,
*                            colwd          = AUTO,
*                            headalign      = C C C C C C,
*                            bodyalign      = C C C C C C,
*                            leftgr         = 3,
*                            byvar          = ,
*                            maxpagedigits  = 3,
*                            grpcont        = N,
*                            nblineslist    = 16
*                            );
*                            
*
* Assumptions:               Styles should be either defined within this macro (see 'proc template' section) or imported from 
*                            external source (see 'ODS template' section).
*
*                            The following macro variables should be defined prior to calling this macro:
*                            1. &_oid. - unique output ID which is pulled from external Excel document. All the hyphens are replaced with underscores by macro since hyphen are illegal in SAS names.
*                            2. &_outnum. - output number is pulled from external Excel document. RTF name will be composed out of output number and ID. Output dataset name will have output ID only.
*                            3. &ls8pt. - Number of monowidth characters that output RTF can fit in a single line using 8pt font size. Normally should we setup once considering company standard output layout. It is used to properly fit and use whole width of the page by global headers (see macro variables below, i.e. &companyname.) and global footnotes like author's name, execution path and time, "page x of y".
*                            4. &ls9pt. - Same as above but using 9pt font size.
*                            5. &watermk. - Blank character which can be generated with %sysfunc(byte(160)). It is used for indentation in output body/header/titles/footnotes.
*                            6. &companyname. - Company name. Printed in upper left corner of the RTF.
*                            7. &deliveryType. - Delivery type (Dry Run, Draft, Final, etc.). Printed in upper right corner of the RTF.
*                            8. &protocol. - Protocol name. Printed in upper left corner of the RTF.
*                            9. &studyend. - study end text. Printed in upper left corner of the RTF. Could be i.e. DBL date or latest data cut date.
*                           10. &deliveryName. - delivery name, i.e. Primary Analysis. Printed in upper left corner of the RTF.
*                           11. &FilePath. - Full path to a program that executes OUTRTF macro. Ideally should be automatically pulled from SAS.
*                           12. &ProgName. - Name of a program that executes OUTRTF macro. Ideally should be automatically pulled from SAS.
*                           13. &RtfOutPath. - path to save RTF output.
*
* Revisions:                
* Revision #	Programmer 	                   Date 	     	   Description of Change(s)
* ----------    ----------------------         ------------        ---------------------------
*
************************************************************************************/
	
%macro koutrtf (inds=&_oid.,
               sortby=data,
               byvar=,
               byformat=,
               colwd=auto,
               headalign=,
               bodyalign=,
               leftgr=0,
               escapechar=@,
               MaxPageDigits=3,
               nblines=17,
               nblineslist=,
               grpcont=N,
               spanhead=,
               splitchar=/,
               wrap=N,
               debug=N);

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
				fontweight = medium
                color=black;

			style systemfooter /
				fontfamily = courier
				fontsize = 9pt
				fontweight = medium
                color=black;
		end;
	run;
    
    /*ODS template*/
    /*ods path (remove) library.templates;
    libname library "&<some_project_path>.\\<template_path>";
    ods path (prepend) library.templates (read);
    ods path show;*/
 
   *--------------------------------------------------------------------------*;
   * &ods_li0 through &ods_li4: levels of indentation using RTF cell margins. *;
   *--------------------------------------------------------------------------*;
 
   %global ods_li0  
           ods_li1 
           ods_li2 
           ods_li3 
           ods_li4 
           ;
   %let ods_li0      = \li%eval(240 * 0);
   %let ods_li1      = \li%eval(240 * 1);
   %let ods_li2      = \li%eval(240 * 2);
   %let ods_li3      = \li%eval(240 * 3);
   %let ods_li4      = \li%eval(240 * 4);
   %let ods_li3      = \li%eval(240 * 3);
   %let ods_li4      = \li%eval(240 * 4);

    *** If dataset has 0 obs then macro will stop execution. ***;
    proc sql noprint;
        select count (v1) into: ___obscnt
        from &inds.;
    quit;

    %if &___obscnt. = 0 %then %do; 
        %put %str(WARN)%str(ING: Input dataset has 0 observations. Macro will STOP execution.); 
        %goto exit;
    %end;
   
    *** Sort input dataset if needed. Otherwise keep sorting as in data. ***;
    %if %sysfunc(upcase(&sortby.)) ^= DATA %then %do;
        proc sort data=&inds. out=___tmp_sort; by &sortby.; run;
    %end;
    %else %do;
        data ___tmp_sort;
            set &inds.;
        run;
    %end;

    *** Permanently save dataset in respective folder. ***;
    data ptlg.&_oid.;
        set ___tmp_sort;
    run;  

    *** Get list of variables ***;
    proc datasets nolist noprint;
        contents data=___tmp_sort out=___tmp_cont;
    run;
    quit;

    %let numby = N;
    *** Replacing _#_ with line breaks in columns headers. ***;
    data ___tmp_cont_trwrd;
        set ___tmp_cont;

        label = tranwrd(label, "_#_", "&escapechar.{newline}");

        %if &byvar. ^= %then %do;
            if strip(name) = "&byvar." and type = 1 then call symput('numby', 'Y');
        %end;
    run;

    *** Get list of variables/number of variables ***;
    proc sql noprint;
        select distinct(name) into: ___varlist separated by " " 
        from ___tmp_cont_trwrd;

        select count (distinct varnum) into: ___varnum
        from ___tmp_cont_trwrd;
    quit;

    *** Automatic columns widths calculated as an equal percentage of page space per eahc column. ***;
    %let autocolwd = %sysevalf(99/&___varnum.);

    *** Pulling variables labels into macro variable that are used to generate columns titles. ***;
    proc sql noprint;
        %do i = 1 %to &___varnum.;
            select name  into: v&i     from ___tmp_cont_trwrd where varnum = &i;
            select label into: v&i.lbl from ___tmp_cont_trwrd where varnum = &i;
            %let v&i.lbl = &&v&i.lbl;
        %end;
    quit;

    *** Replacing _#_ with line breaks in table body. ***;
    data ___tmp_out;
        set ___tmp_sort;

        %do i = 1 %to &___varnum.;
            %if &i. = 1 and &numby. = Y %then %do; %end;
            %else %do; &&v&i. = tranwrd(&&v&i., "_#_", "&escapechar.{newline}"); %end;
        %end;
    run;
 
    data ___tmp_out;
        %if &leftgr. ^= 0 %then %do;
            retain prepage cont;
            length cont $10;
        %end;
        set ___tmp_out;
        %if &byvar. ^= %then %do; by &byvar.; %end;

        if _n_ = 1 then pg = 1;
        n+1;

        *** If list for pagination is not specified, then do pagination with equal number of lines per page. Additionaly new byvar iteration causes +1 page. ***;
        %if &nblineslist. = %then %do;
            if n > %sysevalf(&nblines.) then do;
                pg +1; 
                n=1;
            end;

            %if &byvar. ^= %then %do; 
                if first.&byvar. and _n_ ^= 1 then do;
                    pg + 1;
                    n  = 1;
                end;
            %end;
        %end;

        *** If list of pages is available, then do pagination based on that list. Byvar is ignored in that case. ***;
        %if &nblineslist. ^= %then %do;
            %let nblineslist_num = %sysfunc(countw(&nblineslist.,%str( )));
            %do p=1 %to &nblineslist_num.;
                      %if &p.=1 %then %do; %let totlines = %sysfunc(scan(&nblineslist., &p., " ")); %end;
                %else               %do; %let totlines = %sysevalf(%sysfunc(scan(&nblineslist., &p., " ")) + &totlines.); %end;
                if _n_ <= &totlines. and missing(pg) then pg = &p.;

                if &p.= &nblineslist_num. and missing(pg) then pg = 99999;
            %end;
        %end;

        if _n_ ne 1 and prepage ne pg then difpg = "Y";        

         
        *** Applying ordering variable by lowest level grouping variable. (BYVAL) ***;
        *** Appending text cont for cases with unchaged lower lever grouping variables, but starting a new page. (CONT) ***;
        
              %if &byvar. ^= and &leftgr. ^= 0 %then %do; 
                %do i=1 %to &leftgr.;
                    %let leftgr2 = %sysevalf(&i. + 1);    
                    retain origkey&leftgr2. keycnt&leftgr2.; 
                    length origkey&leftgr2. keycnt&leftgr2. $200; 
                    origkey&leftgr2. = &&v&leftgr2.;
                    if strip(keycnt&leftgr2.) ne strip(origkey&leftgr2.) then do;
                        bycnt&i+1; 
                        call missing(cont);
                    end;
                    %if &grpcont. = Y %then %do;
                        if keycnt&leftgr2. = &&v&leftgr2. and difpg = "Y" then cont = " (cont.)";
                        &&v&leftgr2. = trim(&&v&leftgr2.) || trim(cont);
                    %end;
                    keycnt&leftgr2. = origkey&leftgr2.; 
                %end;
              %end;

        %else %if &byvar.  = and &leftgr. ^= 0 %then %do; 
                %do i=1 %to &leftgr.;
                    %let leftgr2 = &i.;    
                    retain origkey&leftgr2. keycnt&leftgr2.; 
                    length origkey&leftgr2. keycnt&leftgr2. $200; 
                    origkey&leftgr2. = &&v&leftgr2.;
                    if strip(keycnt&leftgr2.) ne strip(origkey&leftgr2.) then do;
                        bycnt&i+1; 
                        call missing(cont);
                    end;
                    %if &grpcont. = Y %then %do;
                        if keycnt&leftgr2. = &&v&leftgr2. and difpg = "Y" then cont = " (cont.)";
                        &&v&leftgr2. = trim(&&v&leftgr2.) || trim(cont);
                    %end;
                    keycnt&leftgr2. = origkey&leftgr2.; 
                %end;
              %end; 

        %else %do;
                bycnt1+1; 
              %end;   

        prepage=pg; 
    run;

    /*V1.01 Update*/
    %if %sysfunc(upcase(&wrap.)) = Y %then %do;
        data ___tmp_out;
            retain highlvl;
            set ___tmp_out;
            by pg;
                
            if strip(substr(&v1.,1,1)) ^= "" then highlvl = strip(&v1.);
            if first.pg and strip(substr(&v1.,1,1)) = "" then do;
                &v1. = strip(highlvl) || " (cont'd)&escapechar.{newline}   " || strip(&v1.);

                %do u = 2 %to &___varnum.;
                    &&v&u. = "&escapechar.{newline}" || trim(&&v&u.);
                %end;
            end;
        run;
    %end; 
    
	%let underline =%sysfunc(repeat(_,%sysevalf(&ls8pt.-4)));

    *** Replacing _#_ with line breaks in titles/footnotes. ***;
    %do i = 1 %to 8;
        %if &i. ^= 1 %then %do; %if "&&f&i" ^= "" %then %do; %let ft&i. = %sysfunc(tranwrd(%str("&&f&i."), _#_, &escapechar.{newline})); %end; %end;
		%if &i.  = 1 %then %do; 
                                %if "&&f&i" = "" %then %do;
                                    %let ft&i. = &underline.&escapechar.{newline}&escapechar.{newline}; 
                                    %let f&i.  = &underline.&escapechar.{newline}&escapechar.{newline}; 
                                %end;
                                %else %do;
                                    %let ft&i. = &underline.&escapechar.{newline}&escapechar.{newline}&&f&i.;  
                                    %let ft&i. = %sysfunc(tranwrd(%str("&&ft&i."), _#_, &escapechar.{newline}));
                                %end;
                           %end;
        %if "&&t&i" ^= "" %then %do; %let tt&i. = %sysfunc(tranwrd(%str("&&t&i."), _#_, &escapechar.{newline})); %end;
    %end;

    *** Last footnote position to populate technical footnote ***;
    %do k=1 %to 8;
        %if "&&f&k" ^= "" %then %do; %let lastFootPos = %sysevalf(&k. + 2); %end;
    %end;

    %if "&f1" = "" %then %do; %let lastFootPos = 3; %end;

    *** Combine overall titles out of study info macro variables coming from SETUP macro ***;
    %let overtitle1 = &companyname.%sysfunc(repeat(&watermk.,%sysevalf(&ls9pt. - %sysfunc(length(&companyname.)) - %sysfunc(length(&deliveryType.)))))&deliveryType.;
    %let overtitle2 = &protocol.%sysfunc(repeat(&watermk.,%sysevalf(&ls9pt. - %sysfunc(length(&protocol.)) - %sysfunc(length(&studyend.)))))&studyend.;
    %let overtitle3 = &deliveryName.%sysfunc(repeat(&watermk.,%sysevalf(&ls9pt. - %sysfunc(length(&deliveryName.)))));

    *** Get timestamp that will be populated in last technical footnote ***;
    %let timestamp = %sysfunc(datetime(), e8601dt16.);

    *** Evaluate length of last technical footnote to populate proper space between pgm path and page number. ***;
    %let lngoverfoot = %sysevalf(&ls8pt. - %sysfunc(length(&sysuserid)) - %sysfunc(length(&FilePath.&ProgName. &timestamp.)) - 12 - (&MaxPageDigits. * 2) );
    
    %if &byvar. ^= %then %do; %let leftgr=%sysevalf(&leftgr. + 1); %end;

    ODS LISTING CLOSE;
    OPTIONS nobyline nodate nonumber center orientation=landscape pagesize=max;
    ODS RTF file = "&RtfOutPath.&_outnum..rtf"
    style=slrn.styles.LandscapeLetterFS8;
    ods escapechar = "&escapechar.";
        proc report data=___tmp_out nowd split="&splitchar."
			missing spanrows 
                        style(report) = [%if &byvar. ^= %then %do; frame=void %end; %else %do; frame=above %end; asis=on rules=groups cellspacing=0 cellpadding=0pt width=100% borderwidth = .1] 
                        style(column) = [asis=on protectspecialchars=off] 
                        style(header) = [asis = on just = c paddingbottom=3mm paddingtop=3mm];
            column pg 
                   /* If LEFTGR = 0 then no columns are grouped on the left. BYCNT1 work just work as a sorting variable in that case. */
                   %if &leftgr. = 0 %then %do;
                        bycnt1 
                   %end;
                   /* Generate macro variable FULLVARLIST. It will remain unchanged if LEFTGR = 0 or ammended with BYVAR variables for each groupiong level, and then
                      passed to PROC REPORT. */
                   %if %length(&spanhead.) =  0 %then %do; %let ___fullvarlist = &___varlist.; %end;
                   %if %length(&spanhead.) ^= 0 %then %do; 
                       %let ___fullvarlist = %sysfunc(tranwrd(%sysfunc(tranwrd(&spanhead.,_#_,&escapechar.{newline})),_$_,&escapechar.S={borderbottomwidth=1}));  
                   %end;
                   %if &leftgr. ^= 0 %then %do u=1 %to &leftgr.;
                        %let ___fullvarlist = %sysfunc(tranwrd(&___fullvarlist., v&u., bycnt&u. v&u.));
                   %end;
                   &___fullvarlist.
                            ;
            define pg/ order noprint;
            /* If LEFTGR = 0 then no columns are grouped on the left. BYCNT1 work just work as a sorting variable in that case. */
            %if &leftgr. = 0 %then %do;
                define bycnt1/ order noprint;
            %end;
            %do i = 1 %to &___varnum.;              
                %if &byvar. ^= %then %do; %let j=%sysevalf(&i. - 1); %end;
                %if &byvar.  = %then %do; %let j=          &i.     ; %end;

                %if &leftgr. ^= 0 and &i. <= &leftgr. %then %do;
                    define bycnt&i./ order noprint;
                %end;

                define &&v&i. / %if &i. = 1 and &byvar. ^= %then %do; noprint order "&&v&i.lbl"; %end;
                                %else %do;                                    
                                    %if %sysevalf(&i. <= &leftgr.) = 1 %then %do; order %end; 
                                    %else %do; display %end;
                                    "&&v&i.lbl" 
                                    style(column)=[%if %sysfunc(upcase(&colwd.))  = AUTO %then %do; width=&autocolwd.%                      %end;
                                                   %if %sysfunc(upcase(&colwd.)) ^= AUTO %then %do; width=%sysfunc(scan(&colwd., &j, " "))% %end;
                                                   just=%sysfunc(scan(&bodyalign., &j, " "))
                                                   asis=on
                                                  ] 

                                    style(header)=[just=%sysfunc(scan(&headalign., &j, " "))
                                                   asis=on]
                                    ;
                                %end;
            %end;

            title1 "&overtitle1.";
            title2 "&overtitle2.";
            title3 "&overtitle3.";
            %do i = 1 %to 6;
                %let j=%sysevalf(&i. + 4);
                %if "&&t&i." ^= "" %then %do; title&j &&tt&i.; %end;
                %if "&&f&i." ^= "" %then %do; footnote&i j=left &&ft&i.; %end;
            %end;                  
            footnote&lastFootPos. "&sysuserid &FilePath.&ProgName. &sysdate9:&systime.%sysfunc(repeat(&watermk.,&lngoverfoot.))Page &escapechar.{thispage} of &escapechar.{lastpage}";

            break after pg/page;

            %if &byvar ^= %then %do;
                compute before _page_ / style = {just=left};;
                    line @1 v0 %if &byformat. ^= %then %do; &byformat.. %end; ; 
                    line %sysevalf(&ls8pt.-4) * "_";
                endcomp;
            %end;

            compute before pg / style = {just=left};;
                line @1 " ";
            endcomp;
        run; 

    ODS RTF CLOSE;
    ODS LISTING


    %exit:;

    %*Delete/keep temporary datasets for debug purposes;
	%if &debug. = N %then %do;
		proc datasets nolist nodetails library = work;
			delete ___tmp_:;
		quit;
	%end;

%mend koutrtf;
