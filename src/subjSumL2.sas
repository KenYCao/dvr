/*
    Program Name: subjectSummary.sas  
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/07

    Generate Subject Summary Sheet for layout2 report.
*/

%macro subjSumL2(site, cat);
    
    %local nIssueType;
    %local i; 
    %local lastTitleLine;
    %local returnRow;
    %local nobs;
    %local nsubj;

    %let cat = %upcase(&cat);

    %let nIssueType = %sysfunc(countc(&allIssueType, @));
    %let nIssueType = %eval(&nIssueType + 1);
    %do i = 1 %to &nIssueType;
        %local issueType&i;
        %let issueType&i = %upcase(%scan(&allIssueType, &i, @));
    %end;

/*    %legend(%if &cat = ALL %then Y; %else N;, NOPRINT);*/

    %let returnRow = %eval(&lastTitleLine + 2);

    data __L2subjSumSheet0;
        set &subjectSummaryDset;
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
    run;

    proc sort data = __L2subjSumSheet0; by subject; run;

    data __L2subjSumSheet;
        set __L2subjSumSheet0;
        length __odd $2;
        __odd = strip(put(mod(_n_, 2), best.));
        length hplink $255;
        hplink = "=HYPERLINK("""||"#'"||strip(subject)||"'!R&returnRow.C1"""||", """||strip(subject)||""")";
    run;

    %getDsetInfo(indata=__L2subjSumSheet, getNOBS=Y);
    %let nsubj = &nobs;

    %if &nsubj = 0 %then %do;
        data __dummy;
            _dummy = 0;
        run;

        data __L2subjSumSheet;
            set __L2subjSumSheet __dummy;
            drop _dummy;
        run;
    %end;

    * title and footers;
    %titleFooters(&bySite, &site);


    ods tagsets.excelxp options(sheet_name="Subject Summary");

    proc report data = __L2subjSumSheet nowd out = &_siteSubjSumDset;
        column ( %if &bySite = N %then 'All Subjects'; %else "ALL SUBJECTS IN SITE &site";
                subject hplink
                %if &compare = N %then %do i = 1 %to &nIssueType; CNT_&i._1   %end; 
                %else %do i = 1 %to &nIssueType; 
                    ("&&issueType&i" CNT_&i._1  CNT_&i._2 CNT_&i._3 CNT_&i._4) 
                %end;   
                __odd 
        );

        define subject / noprint;
        define hplink / 'SUBJECT' style(column) = [foreground=blue textdecoration=underline cellwidth = 1.5in fontsize=10pt font=fonts('font')];
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
        define CNT_&i._1 /  noprint;
        define CNT_&i._2 /  noprint;
        define CNT_&i._4 /  noprint;
        define CNT_&i._3 /  style(column)=[just=l cellwidth=1.5in];
        %end;
        %else %if &cat = REPEAT %then %do;
        define CNT_&i._1 /  noprint;
        define CNT_&i._2 /  noprint;
        define CNT_&i._3 /  noprint;
        define CNT_&i._4 /  style(column)=[just=l cellwidth=1.5in];
        %end;
        %end;
        define __odd / noprint;


        %if &nsubj > 0 %then %do;
        compute __odd;
            if __odd = '0' then call define(_row_, "style", "style=[backgroundcolor=colors('skipcolor')  fontsize=10pt font=fonts('font')]");
        endcomp;

        rbreak after / summarize style(summary) = [background=colors('breakcolor')
            foreground=colors('breakfg') 
            fontstyle=italic
            fontsize=10pt 
            font=fonts('font')
            fontweight=bold];

        compute after / style=[fontstyle=italic];
            hplink = "&odsescapechar{style [foreground=colors('breakfg') fontweight=bold fontsize=10pt font=fonts('font')]TOTAL:}";
        endcomp;
        %end;
        %else %if &nsubj = 0 %then %do;
        compute after / style=[fontstyle=italic just=c fontweight=bold];
            line "No Issue Found";
        endcomp;
        %end;
    run;
    
    /*
    data &_siteSubjSumDset;
        length hplink $255 subject $255;
        if _n_ = 1 then do;
            delcare hash h (dset: '__L2subjSumSheet');
            rc = h.defineKey('hplink');
            rc = h.defineData('subject');
            rc = h.defineDone();
            call missing(hplink, subject);
        end;
        set __L2subjSumSheet1;
        rc = h.find();
        drop rc;
    run;
    */


%mend subjSumL2;
