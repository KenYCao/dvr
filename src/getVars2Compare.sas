/*
    Program Name: getVars2Compare.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/18

    Get variables to be compared in macro %dvpIssueDsetCompare.
*/

%macro getVars2Compare(issueid);

    data _null_;
        set &dvpConfigDset;
        where upcase(issueid) = strip("%upcase(&issueID)");
        call symput('vars2compare', strip(upcase(rptvars2comp)));
    run;

%mend getVars2Compare;


