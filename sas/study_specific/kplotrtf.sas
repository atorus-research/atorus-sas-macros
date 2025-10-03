/**
* @file kplotrtf.sas
* @brief Generate Figure RTF Output
* @details Macro to generate an RTF file from a final statistical graphics procedure.
*          The following macro variables must be defined before execution:
*          - &_oid. - Unique output ID, typically set by %init_oid macro
*          - &ProjectPath. - Base path for accessing project-specific templates
*          - &ls8pt. - Number of monospaced characters for 8pt font size
*          - &ls9pt. - Number of monospaced characters for 9pt font size
*          - &companyname. - Company name for headers
*          - &deliveryType. - Type of delivery (e.g., Draft, Final)
*          - &protocol. - Protocol name for headers
*          - &studyend. - Study end information (e.g., DBL date)
*          - &deliveryName. - Delivery name (e.g., Primary Analysis)
*          - &watermk. - Blank character for spacing, typically %sysfunc(byte(160))
*          - &RtfOutPath. - Path to save generated RTF output
*          - &FilePath. - Full path to executing program
*          - &ProgName. - Name of executing program
*
* @author Atorus Research
* @date 27-Sep-2024
*
* @param[in] call Macro call type: OPEN or CLOSE (Required)
* @param[in] inds Input dataset name (Default: &_oid.)
* @param[in] sortby Variable for sorting the input dataset (Default: DATA for no sorting)
* @param[in] MaxPageDigits Number of digits in the last page indicator for 'Page X of Y' (Default: 1)
* @param[in] escapechar ODS Escape Character to be used (Default: @)
* @param[in] debug Flag to save interim datasets for debugging purposes Y/N (Default: N)
*
* @return RTF file named &oid..rtf
*
* @par Example:
* @code
* %plotrtf(call=OPEN, MaxPageDigits=3);
*     proc sgplot data=...
*         ...
*     quit;
* %plotrtf(call=CLOSE);
* @endcode
*
* @remarks Colors used (bio, dagr, stbr) must be properly defined in advance.
*          External macros like %init_oid need to be included as part of the repository.
*
* @see koutrtf.sas
*
*=============================================================================================*/

%macro plotrtf (call=,
                inds=&_oid.,
                sortby=DATA,
                MaxPageDigits=1,
                escapechar=@,
                debug=N);

    %if %sysfunc(upcase(&call.)) = OPEN %then %do;
        *** ODS template setup *** ;
        ods path (remove) library.templates;
        libname library "&ProjectPath.\%YOUR_PATH_TO_TEMPLATE%";
        ods path (prepend) library.templates (read);
        ods path show;

        proc template;
            define style plotstandard;
                parent = %YOUR_PARRENT_TEMPLATE%;

                *** Setting styles for output appearance *** ;
                class body, data /
                    fontfamily="Courier new"
                    fontsize=8pt
                    backgroundcolor=white
                    color=black;

                style GraphFonts /
                    'GraphDataFont'      = ("Courier new", 8pt)
                    'GraphUnicodeFont'   = ("Courier new", 8pt)
                    'GraphValueFont'     = ("Courier new", 8pt)
                    'GraphLabelFont'     = ("Courier new", 8pt)
                    'GraphFootnoteFont'  = ("Courier new", 8pt)
                    'GraphTitleFont'     = ("Courier new", 8pt)
                    'GraphAnnoFont'      = ("Courier new", 8pt)
                    'NodeLinkLabelFont'  = ("Courier new", 8pt)
                    'GraphLabel2Font'    = ("Courier new", 8pt)
                    'GraphTitle1Font'    = ("Courier new", 8pt)
                    'NodeTitleFont'      = ("Courier new", 8pt)
                    'NodeLabelFont'      = ("Courier new", 8pt)
                    'NodeInputLabelFont' = ("Courier new", 8pt)
                    'NodeDetailFont'     = ("Courier new", 8pt)
                    ;

                style GraphAxisLines / Linethickness = 1px;
                style GraphWalls / frameborder = off;

                *** Defining graph styles with colors *** ;
                style Graphdata1  / markersymbol="TriangleFilled"      Linestyle =  1 color=black     contrastcolor=black     end;
                style Graphdata2  / markersymbol="SquareFilled"        Linestyle =  2 color=blue      contrastcolor=blue      end;
                style Graphdata3  / markersymbol="CircleFilled"        Linestyle =  3 color=darkgreen contrastcolor=darkgreen end;
                style Graphdata4  / markersymbol="Plus"                Linestyle =  8 color=bio       contrastcolor=bio       end;
                style Graphdata5  / markersymbol="X"                   Linestyle = 20 color=dagr      contrastcolor=dagr      end;
                style Graphdata6  / markersymbol="TriangleDownFilled"  Linestyle = 33 color=stbr      contrastcolor=stbr      end;

                style fonts /
                    'footFont' = ("Courier new",8pt)
                    'docFont' = ("Courier new",8pt)
                    'headingFont' = ("Courier new",8pt)
                    'headingEmphasisFont' = ("Courier new",11pt,bold italic)
                    'FixedFont' = ("Courier new",2)
                    'BatchFixedFont' = ("SAS Monospace, Courier",2)
                    'FixedHeadingFont' = ("Courier new",2)
                    'FixedStrongFont' = ("Courier new",2,bold)
                    'FixedEmphasisFont' = ("Courier new",2,italic)
                    'EmphasisFont' = ("Courier new",8pt,italic)
                    'StrongFont' = ("Courier new",8pt,bold)
                    'TitleFont' = ("Courier new",9pt)
                    'TitleFont2' = ("Courier new",11pt,bold italic);
           end;
        run;

       *** Defining indentation levels for RTF cell margins *** ;
       %global ods_li0 ods_li1 ods_li2 ods_li3 ods_li4;
       %let ods_li0 = \li%eval(240 * 0);
       %let ods_li1 = \li%eval(240 * 1);
       %let ods_li2 = \li%eval(240 * 2);
       %let ods_li3 = \li%eval(240 * 3);
       %let ods_li4 = \li%eval(240 * 4);

       *** Check if the dataset has observations *** ;
        proc sql noprint;
            select count(*) into :___obscnt from &inds.;
        quit;

        %if &___obscnt. = 0 %then %do;
            %put WARNING: Input dataset has 0 observations. Macro will STOP execution.;
            %goto exit;
        %end;

        *** Sort the input dataset if needed *** ;
        %if %sysfunc(upcase(&sortby.)) ^= DATA %then %do;
            proc sort data=&inds. out=___tmp_sort; by &sortby.; run;
        %end;
        %else %do;
            data ___tmp_sort;
                set &inds.;
            run;
        %end;

        *** Save dataset permanently in the output folder *** ;
        data ptlg.&_oid.;
            set ___tmp_sort;
        run;

        %let underline = %sysfunc(repeat(_,%sysevalf(&ls8pt.-4)));

        *** Replace line breaks in titles and footnotes *** ;
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

        *** Last footnote position for technical footnote *** ;
        %do k=1 %to 8;
            %if "&&f&k" ^= "" %then %do; %let lastFootPos = %sysevalf(&k. + 2); %end;
        %end;
        %if "&f1" = "" %then %do; %let lastFootPos = 3; %end;

        *** Define global titles from setup macro variables *** ;
        %let overtitle1 = &companyname.%sysfunc(repeat(&watermk.,%sysevalf(&ls9pt. - %sysfunc(length(&companyname.)) - %sysfunc(length(&deliveryType.)))))&deliveryType.;
        %let overtitle2 = &protocol.%sysfunc(repeat(&watermk.,%sysevalf(&ls9pt. - %sysfunc(length(&protocol.)) - %sysfunc(length(&studyend.)))))&studyend.;
        %let overtitle3 = &deliveryName.%sysfunc(repeat(&watermk.,%sysevalf(&ls9pt. - %sysfunc(length(&deliveryName.))));

        *** Get timestamp for technical footnote *** ;
        %let timestamp = %sysfunc(datetime(), e8601dt16.);

        *** Calculate space for last technical footnote *** ;
        %let lngoverfoot = %sysevalf(&ls8pt. - %sysfunc(length(&sysuserid)) - %sysfunc(length(&FilePath.&ProgName. &timestamp.)) - 12 - (&MaxPageDigits. * 2));

        *** Open ODS RTF destination *** ;
        ODS LISTING CLOSE;
        OPTIONS nobyline nodate nonumber center orientation=landscape pagesize=max;
        ods graphics / noborder;
        ODS RTF file = "&RtfOutPath.&_outnum..rtf"
        style=plotstandard;
        ods escapechar = "&escapechar.";

        title1 "&overtitle1.";
        title2 "&overtitle2.";
        title3 "&overtitle3.";
        %do i = 1 %to 6;
            %let j=%sysevalf(&i. + 4);
            %if "&&t&i." ^= "" %then %do; title&j &&tt&i.; %end;
        %end;
        %do i = 1 %to 8;
            %if "&&f&i." ^= "" %then %do; footnote&i j=left &&ft&i.; %end;
        %end;
        footnote&lastFootPos. "&sysuserid &FilePath.&ProgName. &sysdate9:&systime.%sysfunc(repeat(&watermk.,&lngoverfoot.))Page &escapechar.{thispage} of &escapechar.{lastpage}";
    %end;
    %else %if %sysfunc(upcase(&call.)) = CLOSE %then %do;
        ODS RTF CLOSE;
        ODS LISTING;
    %end;

    %exit:;

    *** Delete or keep debug datasets *** ;
    %if &debug. = N %then %do;
        proc datasets nolist nodetails library=work;
            delete ___tmp_:;
        quit;
    %end;

%mend plotrtf;
