/*
    Program Name: getnrefdset.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/23

    return # of reference datasets of a issue
*/

%macro getNRefDset(issueid);
    
    %let nrefdset = 0;

    data _null_;
        set &dvpRefConfigDset;
        where issueid = "&issueID";
        call symput('nrefdset', strip(put(nrefdset, best.)));
    run;

%mend getNRefDset;
