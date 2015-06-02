/*
    Program Name: dsetSumL2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/07

    Generate dataset summary sheet.

   Revision History:
   Ken Cao 2014/07/01: Fix a bug when __L2dsetSumSheet has 0 observations.

*/



%macro dsetSumL2(site, cat);
    
    %local nIssueType;
    %local i;
    %local lastTitleLine;
    %local nobs;

    %let cat = %upcase(&cat);
    
    %let nIssueType = %sysfunc(countc(&allIssueType, @));
    %let nIssueType = %eval(&nIssueType + 1);
    %do i = 1 %to &nIssueType;
        %local issueType&i;
        %let issueType&i = %upcase(%scan(&allIssueType, &i, @));
    %end;
    
    data __L2dsetSumSheet0;
        set &dsetSummaryDset;
        where site = "&site"
        %if &cat = ALL %then
        and 1;
        %else %if &cat = NEW %then
        and nobsnew > 0;
        %else %if &cat = MODIFIED %then
        and nobsmdf > 0;
        %else %if &cat = REPEAT %then
        and nobsrpt > 0;
        ;
        drop site;
    run;

    proc sort data =  __L2dsetSumSheet0; by sdset; run;

    data __L2dsetSumSheet;
        set __L2dsetSumSheet0;
        length __odd $2;
        __odd = strip(put(mod(_n_, 2), best.));

        * replace '0A'x with SAS inline formatting - new line;
        sdsetlbl = tranwrd(sdsetlbl, '0A'x, "&odsEscapeChar.n");

        * replace punctions with SAS inline formatting - new line;
        sdset = prxchange('s/[^a-z_\d]\s*/*/i', -1, strip(sdset));
        sdset = tranwrd(sdset, '*', "&odsEscapeChar.n");
    run;


    %titleFooters(&bySite, &site);
    * remove footnote;
    footnote;

    %getDSetInfo(indata=__L2dsetSumSheet, getNOBS=Y);

    %if &nobs = 0 %then %do;
        data __dummy;
            _dummy = 0;
        run;

        data __L2dsetSumSheet;
            set __L2dsetSumSheet __dummy;
            drop _dummy;
        run;
    %end;

    ods tagsets.excelxp options(sheet_name = "Dataset Summary");

    proc report data = __L2dsetSumSheet nowd out = &_siteDsetSumDset;
        column ('Processed Source Datasets' sdset sdsetlbl 
        %if &compare = N %then %do i = 1 %to &nIssueType; CNT_&i._1   %end; 
        %else %do i = 1 %to &nIssueType; 
            ("&&issueType&i" CNT_&i._1  CNT_&i._2 CNT_&i._3 CNT_&i._4) 
        %end;
        __odd); 
        define sdset / 'Source Dataset' style(column)=[cellwidth = 1.2in];
        define sdsetlbl / 'Label' style(column)=[cellwidth = 4in];
        define __odd / noprint;
        %if &compare = N %then %do i = 1 %to &nIssueType;
        define CNT_&i._1 / "&&issueType&i" style(column)=[just=l cellwidth=1.2in];
        %end;
        %else %do i = 1 %to &nIssueType;
        define CNT_&i._1 /  'Total'    style(column)=[just=l cellwidth=0.5in];
        define CNT_&i._2 /  'New'      style(column)=[just=l cellwidth=0.5in];
        define CNT_&i._3 /  'Modified' style(column)=[just=l cellwidth=0.8in];
        define CNT_&i._4 /  'Repeat'   style(column)=[just=l cellwidth=0.6in];
        %if &cat = ALL %then %do;
        %end;
        %else %if &cat = NEW %then %do;
        define CNT_&i._1 /  noprint;
        define CNT_&i._3 /  noprint;
        define CNT_&i._4 /  noprint;
        define CNT_&i._2 /  style(column)=[just=l cellwidth=1.5in];
        %end;
        %else %if &cat = MODIFIED %then %do;
        define CNT_&i._1 / noprint;
        define CNT_&i._2 / noprint;
        define CNT_&i._4 /  noprint;
        define CNT_&i._3 /  style(column)=[just=l cellwidth=1.5in];
        %end;
        %else %if &cat = REPEAT %then %do;
        define CNT_&i._1 / noprint;
        define CNT_&i._2 / noprint;
        define CNT_&i._3 / noprint;
        define CNT_&i._4 /  style(column)=[just=l cellwidth=1.5in];
        %end;
        %end;

        %if &nobs > 0 %then %do;
         compute __odd;
            if __odd = '0' then call define(_row_, "style", "style=[backgroundcolor=colors('skipcolor')]");
         endcomp;

         rbreak after / summarize style(summary) = [background=colors('breakcolor')
            foreground=colors('breakfg')
            fontstyle=italic fontweight=bold
            fontsize=10pt 
            font=fonts('font')
            ];

         compute after/style=[fontsize=10pt font=fonts('font')];
            sdset = 'TOTAL:';
         endcomp;
         %end;
         %else %do;
         compute after / style=[fontstyle=italic just=c fontweight=bold fontsize=10pt font=fonts('font')];
            line "No Issue Found";
         endcomp;
         %end;
    run;


%mend dsetSumL2;
