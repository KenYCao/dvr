/*
    Program Name: issueSumL2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/07
    
    Generate issue summary sheet.

    Ken Cao on 2014/05/16: Group issue summary table by Issue Type first.
    
*/



%macro issueSumL2(site, cat, noprint=);

    %local lastTitleLine;
    %local _1stissuestartnum;

    %let cat = %upcase(&cat);

    data __L2issueSumSheet0;
        set &issueSummaryDset;
        %if &cat = NEW %then
        nobs = nobsnew;
        %else %if &cat = MODIFIED %then
        nobs = nobsmdf;
        %else %if &cat = REPEAT %then
        nobs = nobsrpt;
        ;
        where site = "&site"
        %if &showALLissueIDinIssueSum = N %then %do;
        and nobs > 0;
        %end;
        ;
    run;


    data __L2issueSumSheet1;
        set __L2issueSumSheet0;
        length hplink $255 _hplnkfg $1;
        call missing(hplink, _hplnkfg);
        if nobs > 0 then do;
            hplink = "=HYPERLINK("""||"#'ISSUE DETAILS'!"||strip(issueid)||""", """||strip(issueid)||""")";;
            _hplnkfg = 'Y';
        end;
        else hplink = issueid;
    run;


/*    proc sort data = __L2issueSumSheet1; by sdset issueid; run;*/
    proc sort data = __L2issueSumSheet1; by issueTyp issueid; run;

    data __L2issueSumSheet;
        set __L2issueSumSheet1;
        length __odd $1;
        __odd = strip(put(mod(_n_, 2), best.));
    run;
    
    * title and footers;
    %titleFooters(&bySite, &site);
    footnote;

    ods tagsets.excelxp 
    options(
        sheet_name            = "Issue Summary"
        sheet_interval        = 'Table'
        hidden_columns        = '0'
        frozen_headers        = 'yes'
    );;

    proc report data = __L2issueSumSheet nowd out = &_siteIssueSumDset;
        column ('Issue Summary'  site issuetyp issueid hplink  sdset  message  nobs %if &compare = Y %then nobsnew nobsmdf nobsrpt; __odd _hplnkfg);
        define site / noprint order;
        define issuetyp/'Severity'  order style(column)=[cellwidth=1.8in just=l] ;
        define issueid / noprint order;
        define hplink/'Issue ID' style(column)=[cellwidth=2.2in just = l font = fonts('font') fontsize = 10pt];
        define sdset/'Source Dataset' style(column)=[cellwidth=1.5in];
        define message/'Message' style(column)=[cellwidth=6in just=l];
        %if &compare = N %then %do;
        define nobs / 'Found' style(column)=[cellwidth=1in just=l];
        %end;
        %else %do;
        define nobs / 'Total' style(column)=[cellwidth=0.7in just=l];
        define nobsnew/ 'New' style(column)=[cellwidth=0.7in just=l];
        define nobsmdf / 'Modified' style(column)=[cellwidth=0.7in just=l];
        define nobsrpt / 'Repeat' style(column)=[cellwidth=0.7in just=l];
        %if &cat = ALL %then %do;
        %end;
        %else %if &cat = NEW %then %do;
        define nobs / noprint;
        define nobsmdf / noprint;
        define nobsrpt / noprint;
        %end;
        %else %if &cat = MODIFIED %then %do;
        define nobs / noprint;
        define nobsnew/ noprint;
        define nobsrpt / noprint;
        %end;
        %else %if &cat = REPEAT %then %do;
        define nobs / noprint;
        define nobsnew/ noprint;
        define nobsmdf / noprint;
        %end;
        %end;

        define __odd / noprint;
        define _hplnkfg / noprint;

        compute __odd;
            if __odd = '0' then call define(_row_, "style", "style=[backgroundcolor=colors('skipcolor') fontsize=10pt font=fonts('font')]");
        endcomp;

        compute _hplnkfg;
            if _hplnkfg = 'Y' then call define('hplink', 'style', "style=[foreground=blue textdecoration=underline fontsize=10pt font=fonts('font')]");
        endcomp;

        break before issueTyp / summarize style(summary) = [background=colors('breakcolor') foreground=colors('breakfg') 
                            fontstyle=italic fontweight=bold font=fonts('font') fontsize=10pt];

        break after site/ summarize style(summary) = [background=colors('breakcolor') foreground=colors('breakfg')
                                    fontstyle=italic fontweight=bold font=fonts('font') fontsize=10pt];

        compute after site;
            issueTyp = "&odsescapechar{style [foreground=white fontweight=bold fontsize=10pt font=fonts('font')]TOTAL # of Issues:}";
        endcomp;
    run;

    %if &noPrint = Y %then ods tagsets.excelxp exclude none;

%mend issueSumL2;
