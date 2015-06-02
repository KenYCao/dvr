/*
    Program Name: getGlbVarNum.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/21

    Get maximum # of report variables (for display purpose)

*/

* glbvarNum should be defined local in parent macro ;


%macro getGlbVarNum(issueid);

    %let glbvarNum = 0;
 
    proc sql noprint;
        select nglb
        into: glbvarNum
        from &dvpConfigDset
        where issueid = "&issueid"
        ;
    quit;

%mend getGlbVarNum;
