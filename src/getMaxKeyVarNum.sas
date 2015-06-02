/*
    Program Name: getMaxKeyVarNum.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/06

    Get maximum # of key variables (for display purpose)

*/

* maxKeyVarNum should be defined local in parent macro ;

%macro getMaxKeyVarNum();
    
    proc sql noprint;
        select max(nkey)
        into: maxKeyVarNum
        from &dvpConfigDset
        where nobs > 0
        ;
    quit;

%mend getMaxKeyVarNum;
