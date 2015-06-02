/*
    Program Name: getMaxGlbVarNum.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/06

    Get maximum # of report variables (for display purpose)

*/

* maxGlbVarNum should be defined local in parent macro ;

%macro getMaxGlbVarNum();
    
    proc sql noprint;
        select max(nglb)
        into: maxGlbVarNum
        from &dvpConfigDset
        where nobs > 0
        ;
    quit;

%mend getMaxGlbVarNum;
