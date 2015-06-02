/*
    Program Name: getReturnRowIssueD.sas
        @Author: Ken Cao(yong.cao@q2bi.com)
        @Initial Date: 2014/04/03

*/

%macro getReturnRowIssueD(issueid);

    %local indexTBLstartRow;
    %local lastTitleLine;

    %titleFooters(&bySite);
    %let indexTBLstartRow = %eval(&lastTitleLine + 2);

    * reset titles and footnotes;
    title; footnote;


    * get return row number of the issue;
    data _null_;
        set &_siteIssueSumdset;
        if upcase(issueid) = "&issueid" then
            do;
                returnrow = _n_ + &indexTBLstartRow + 2 - 1; /* 2: # of header lines */
                call symput('returnrow', strip(put(returnrow, best.)));
                stop;
            end;
    run;

%mend getReturnRowIssueD;
