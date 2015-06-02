/*
    Program Name: getKeyVarNum.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/21

    get # of key variables (for display purpose)

*/

* keyvarNum should be defined local in parent macro ;

%macro getKeyVarNum(issueid);

    %let keyvarNum = 0;
    
    proc sql noprint;
        select nkey
        into: keyvarNum
        from &dvpConfigDset
        where issueid = "&issueid"
        ;
    quit;

%mend getKeyVarNum;
