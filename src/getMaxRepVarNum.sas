/*
    Program Name: getMaxRepVarNum.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/06

    Get maximum # of report variables (for display purpose)

*/

* maxRepVarNum should be defined local in parent macro ;

%macro getMaxRepVarNum();
    
    proc sql noprint;
        select max(nrep)
        into: maxRepVarNum
        from &dvpConfigDset
        where nobs > 0
        ;
    quit;

%mend getMaxRepVarNum;
