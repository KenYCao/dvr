/*
    Program Name: getRefVars.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/21

    return reference variables;
*/

%macro getRefVars(issueID, refDset);

    %let refvars = %str();

    data _null_;
        set &dvpRefConfigDset;
        where issueid = "&issueID" and upcase(refdset) = upcase(strip("&refDset"));
        length __refvars $1024;
        if kdflag = 'K' then __refvars = 'keep';
        else if kdflag = 'D' then __refvars = 'drop';
        __refvars = strip(__refvars)||' '||strip(refvars);
        call symput('refvars', strip(__refvars));
    run;

%mend getRefVars;
