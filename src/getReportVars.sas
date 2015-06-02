/*
    Program Name: getReportVars.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/11

    Get report variables for a issue
*/


%macro getReportVars(issueID);

    data _null_;
        set &dvpConfigDset;
        where upcase(issueid) = strip("%upcase(&issueID)");

        length _ALLrepvars $1024;
        array repv{*} repvar:;
        do i = 1 to dim(repv);
            if repv[i] = ' ' then continue;
            _ALLrepvars = strip(_ALLrepvars) || ' ' || repv[i];
        end;
        call symput('reportvars', strip(upcase(_ALLrepvars)));
    run;


%mend getReportVars;
