/*
    Program Name: dvpRepL1.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Intial Date: 2014/01/01
    Report normalized reports
*/


/*************************************************************************************
REVISION HISTORY

2014/03/10 Ken Cao: Add a blank column Q2COMMENT in the end.

*************************************************************************************/



%macro dvpRepL1();

    %local nameprefix;
    %local dsetSummaryDset;
    %local issueSummaryDset;
    %local allIssueNMDset;
    %local time;
    %local date;
    %local maxrepvarnum;
    %local maxkeyvarnum;
    %local glbvcnt;
    %local i;

    /* Hard Code */
    %let nameprefix       = %str(Q2_Data_Validation_Report_Normalized_);
    %let dsetSummaryDset  = %str(_dvpSdsetSummary);
    %let issueSummaryDset = %str(_dvpIssueSummary);
    %let allIssueNMDset   = %str(_dvpAllIssueNM);


    %getMaxRepVarNum;
    %getMaxKeyVarNum;

    %getDateTime;


    * titles and footnotes;
    %titleFooters(N);

    ods tagsets.ExcelXP path="&outputdir" file="&nameprefix.&studyid2._&date.T&time..xml" style=sasweb
    options(
            orientation='landscape'
            autofit_height="yes"
            wraptext="yes"
            fittopage="yes"
            gridlines="no"
            embedded_titles='yes'
            embedded_footnotes='yes'
            frozen_headers='yes'
            );


    **********************************************************************************************************************;
    * Dataset Summary Sheet;
    **********************************************************************************************************************;
    
    %DsetSummary(&allSiteTXT);
    
    **********************************************************************************************************************;
    * Issue Summary Sheet;
    **********************************************************************************************************************;
    
    %issueSumL1(&allSiteTXT);

    
    **********************************************************************************************************************;
    * Detail Sheet;
    **********************************************************************************************************************;
    %stripCompbl(globalvars, &globalvars);

    %let glbvcnt = %sysfunc(ifc(%length(&globalvars) = 0, -1, %eval(%sysfunc(countc(&globalvars, @)) + 1)));

    %do i = 1 %to &glbvcnt;
        %local glbvar&i;
        %local glbvlbl&i;
        %let glbvar&i   = %upcase(%scan(%scan(&globalvars, &i, @), 1, %str(())));
        %let glbvlbl&i  = %nrbquote(%scan(%scan(&globalvars, &i, @), 2, %str(())));
    %end;

    data __prt;
        set &allIssueNMDset;
        %if &compare = N %then
            %do;
                length __odd $2;
                __odd = strip(put(mod(_n_, 2), best.));
            %end;
    run;

    ods tagsets.excelxp options
        (
        sheet_name="Details" 
        sheet_interval = 'none' 
        %if &compare=N %then 
            %do;
                embedded_titles='no'
                embedded_footnotes='no'
            %end;
        autofilter='yes'
        );
    title;footnote;
    /*
    %if &compare = Y %then %do;
        title1 height=10pt j=c "&odsescapechar{style[foreground=white]}";
        title2 height=10pt bcolor="&newcolor" j=l bold "New Issue";
        title3 height=10pt bcolor="&mdfcolor" j=l bold "The record was modified in new data transfer";
    %end;
    */

    ****************************************************************************************;
    * Lgend lines:
    * * * Go back to Subject Summary Sheet
    * * * Sample of new issue records
    * * * Sample of modified records
    ****************************************************************************************;
    %legend;


    ****************************************************************************************;
    * All issue in normalized structure:
    ****************************************************************************************;

    proc report data = __prt nowd style(column)=[tagattr='format:@'] split="&splitChar";
        format _numeric_ best32.;
        column  
            %if &reviewonly = Y %then %str( __recid );
            %if &compare = Y %then %str(_type_ _diff_);
            issueid message issuetyp
            %do i = 1 %to &glbvcnt;
                %str( &&glbvar&i )
            %end;
            sdset sdsetlbl
            %do i=1 %to &maxkeyvarnum; %str( keyvlbl_&i keyvar_&i) %end;
            %do i=1 %to &maxrepvarnum; %str( repvlbl_&i repvar_&i) %end;
            __odd __q2cmnt;
        %if &reviewonly = Y %then %do;
        define __recID / 'Record ID' style(column) = [cellwidth=2.8in];
        %end;
        define issueid/'ISSUE ID' style(column)=[cellwidth=1.8in];
        define message/'MESSAGE' style(column)=[cellwidth=3.0in just=l tagattr='general'];
        define issuetyp/'Severity' style(column)=[cellwidth=1.2in just=l];
        define sdset/noprint;
        define sdsetlbl/'DATASET' style(column)=[cellwidth=3.0in just=l];
        %do i=1 %to &glbvcnt;
            define &&glbvar&i/"&&glbvlbl&i" style(column)=[cellwidth=2.0in];
        %end;
        %do i=1 %to &maxkeyvarnum;
            define keyvlbl_&i/"Key Variable &i" style(column)=[cellwidth=2.0in];
            define keyvar_&i/"Key Variable#Value &i" style(column)=[cellwidth=2.0in];
        %end;
        %do i=1 %to &maxrepvarnum; 
            define repvlbl_&i/"Query Variable &i" style(column)=[cellwidth=2.0in];
            define repvar_&i/"Query Variable#Value &i" style(column)=[cellwidth=2.0in];
        %end;
        %if &compare = Y %then
            %do;
                define _type_/'N=New#M=Modified' style(column)=[cellwidth=1.0in];;
                define _diff_/ 'Modification Detail' style(column)=[cellwidth=2.8in tagattr='format:general'];
            %end;
        define __odd/ noprint;
        define __q2cmnt/'Q2 COMMENT' style(column)=[cellwidth = 2.5in];

        %if &compare = Y %then 
            %do;
                compute _type_;
                    if _type_ = 'M' then call define(_row_, "style", "style=[backgroundcolor=&mdfcolor]");
                    if _type_ = 'N' then call define(_row_, "style", "style=[backgroundcolor=&newcolor]");
                endcomp;
            %end;
        %else 
            %do;
                compute __odd;
                    if __odd='0' then call define(_row_, "style", "style=[backgroundcolor=&skipColor]");
                endcomp;
            %end;
        ;
    run;

    ods tagsets.excelxp close;

%mend dvpRepL1;

