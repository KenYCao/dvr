/*
    Program Name: getRepVarNum.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/21

    Get # of report variables of a issue (for display purpose)

*/

* RepVarNum should be defined local in parent macro ;

%macro getRepVarNum(issueid);

    %let repvarNum = 0;
    
    proc sql noprint;
        select nrep
        into: repvarNum
        from &dvpConfigDset
        where issueid = "&issueid"
        ;
    quit;

%mend getRepVarNum;
