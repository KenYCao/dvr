/*
    Program Name: siteSummary.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date : 2014/03/09

    Generate Site Summary Sheet.

*/

%macro siteSummary();
    
    %local nIssue;
    %local i;


    data __prt;
        set &siteSummaryDset;
        length hplink $512 __odd $1;
        %if &bySite = Y %then
        hplink = "=HYPERLINK("""||strip(filename)||"#'Subject Summary'!R1C1"", """||strip(site)||""")";
        %else
        hplink = site;
        ;
        __odd  = strip(put(mod(_n_, 2), best.));
        where 1
        /*
        %if %length(&sites) > 0 %then
        and findw(strip("&sites"), strip(upcase(site)), '@') > 0;
        */
        %if &bysite = Y %then
        and site ^= "&allSiteTXT";
        ;
    run;

    %let nIssueType = %sysfunc(countc(&allIssueType, @));
    %let nIssueType = %eval(&nIssueType + 1);
    %do i = 1 %to &nIssueType;
        %local issueType&i;
        %let issueType&i = %upcase(%scan(&allIssueType, &i, @));
    %end;

    
    ods tagsets.excelxp options(sheet_name = "Site Summary");
    proc report data = __prt nowd split = '$';
        column ('ALL SITES' hplink nsubject
        %if &compare = N %then %do i = 1 %to &nIssueType; CNT_&i._1   %end; 
        %else %do i = 1 %to &nIssueType; 
            ("&&issueType&i" CNT_&i._1  CNT_&i._2 CNT_&i._3) 
        %end;
        __odd
        );
        
        %if &bysite = Y %then %do;
        define hplink / 'SITE' style(column) = [foreground=blue textdecoration=underline fontweight=bold cellwidth=1in];
        %end;
        %else %do;
        define hplink / 'SITE' style(column) = [cellwidth=1in];
        %end;
        define nsubject / '# of Subjects$with Issue' style(column) = [cellwidth = 1.2in];

        %if &compare = N %then %do i = 1 %to &nIssueType;
        define CNT_&i._1 / "&&issueType&i" style(column)=[just=l cellwidth=1.2in];
        %end;
        %else %do i = 1 %to &nIssueType;
        define CNT_&i._1 /  'Total'    style(column)=[just=l cellwidth=0.5in];
        define CNT_&i._2 /  'New'      style(column)=[just=l cellwidth=0.5in];
        define CNT_&i._3 /  'Modified' style(column)=[just=l cellwidth=0.8in];
        %end;
        define __odd / noprint;

        compute __odd;
            if __odd = '0' then call define(_row_, "style", "style=[backgroundcolor=&skipcolor]");
        endcomp;

        rbreak after / summarize style(summary) = [background=&breakcolor fontstyle=italic fontweight=bold];

        compute after / style=[foreground=black fontweight=bold fontstyle=italic];
            hplink = 'TOTAL:';
        endcomp;
    run;

%mend siteSummary;
