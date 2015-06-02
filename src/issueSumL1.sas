/*
    Program Name: issueSumL1.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/07
    
    Generate issue summary sheet in layout 1 report.
    
*/



%macro issueSumL1(site);

    /*
    %local skipcolor;
    %local breakcolor;
    %let skipcolor  = #DBEEF3;
    %let breakcolor = #FDF3D9;
    */

    data __prt0;
        set &issueSummaryDset;
        where site = "&site"
        and nobs > 0; /* exclude issues of no records */
    run;

    proc sort data = __prt0; by sdset issueid; run;

    data __prt;
        set __prt0;
        length __odd $2;
        __odd = strip(put(mod(_n_, 2), best.));
    run;

    ods tagsets.excelxp options(sheet_name="Issue Summary");

    proc report data = __prt nowd;
        column ('Issue Summary'  sdset issueid issuetyp message  nobs %if &compare = Y %then nobsnew nobsmdf; __odd );
        define sdset/'Source Dataset' order style(column)=[cellwidth=1.5in];
        define issueid/'Issue ID' style(column)=[cellwidth=1.8in];
        define issuetyp/'Severity'  style(column)=[cellwidth=1.2in just=l] ;
        define message/'Message' style(column)=[cellwidth=6in just=l];
        %if &compare = N %then
            %do;
                  define nobs / 'Found' style(column)=[cellwidth=1in just=l];
            %end;
        %else
            %do;
                define nobs / 'Total' style(column)=[cellwidth=0.7in just=l];
                define nobsnew/ 'New' style(column)=[cellwidth=0.7in just=l];
                define nobsmdf / 'Modified' style(column)=[cellwidth=0.7in just=l];
            %end;

        define __odd/noprint;

        compute __odd;
            if __odd = '0' then call define(_row_, "style", "style=[backgroundcolor=&skipcolor]");
        endcomp;

        break before sdset / summarize style(summary) = [background=&breakcolor fontstyle=italic fontweight=bold];

    run;

%mend issueSumL1;
