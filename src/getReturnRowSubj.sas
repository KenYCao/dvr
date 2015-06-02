/*
    Program Name: getReturnRowSubj.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/03
*/

%macro getReturnRowSubj(subject);

    %local indexTBLstartRow;
    %local lastTitleLine;

    %titleFooters(&bySite, XX);
    %let indexTBLstartRow = %eval(&lastTitleLine + 2);
     
    title; footnote;


    /*
    data _allSubject;
        set &subjectSummaryDset;
        where 1
        %if &bySite = Y %then
        and site = "&site";
        %if &cat = ALL %then
        and 1;
        %else %if &cat = NEW %then
        and nobsnew > 0;
        %else %if &cat = MODIFIED %then
        and nobsmdf > 0;
        %else %if &cat = REPEAT %then
        and nobsrpt > 0;
        ;
        keep subject;
    run;
    
    proc sort data = _allSubject; by subject; run;
    */

    %let returnRow = 0;

    data _null_;
/*        set _allSubject;*/
        set &_siteSubjSumDset;
        if subject = "&subject" then 
            do;
                returnrow = &indexTBLstartRow + _n_ + %if &compare = Y %then 3; %else 2; - 1; /* 3/2: # of lines of header */
                call symput('returnrow', strip(put(returnrow, best.)));
                stop;
            end;
    run;

%mend getReturnRowSubj;
