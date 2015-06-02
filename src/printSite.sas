/*
    Program Name: printSite.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/13

    print all subjects of a site or of all sites.

    REVISION HISTORY:
    2014/03/28 Ken Cao: Hide (rather than remove) record ID when reviewonly is set to N.
*/

%macro printSite(site, cat);

    %local nSubject;
    %local i;


    %let cat = %upcase(&cat);

    data _allSubject;
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

    proc sql noprint;
        select count(distinct subject)
        into: nsubject
        from _allSubject
    quit;

    %do i = 1 %to &nSubject;
        %local subject&i;
    %end;

    data _null_;
        set _allSubject;
        call symput('subject'||strip(put(_n_, best.)), strip(subject));
    run;

    %do i = 1 %to &nSubject;
        title; footnote;
        /*
            skip_space
            The default values are:
            Table  : 1
            Byline : 0
            Title  : 1
            Footer : 1
            PageBreak : 1
        */
        ods tagsets.excelxp
        options(
            sheet_name            = "&&subject&i"
            sheet_interval        = 'none' 
            frozen_headers        = 'no'
            absolute_Column_Width = '30'
            skip_space            = '2, 0, 1, 1, 1'
            %if &reviewOnly = N %then
            hidden_columns        = '1';
        );



        ****************************************************************************************;
        * Print each issue dataset
        ****************************************************************************************;
        %printSubject(&&subject&i, &cat);

    %end;






%mend printSite;
