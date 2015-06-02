/*
    Program Name: getKeyVars4Compare.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/11

    Get key variables for compare purpose
*/


%macro getKeyVars4Compare(issueID);

    data _null_;
        set &dvpConfigDset;
        where upcase(issueid) = strip("%upcase(&issueID)");

        call symput('keyvars4comp', strip(upcase(key4comp)));
    run;


%mend getKeyVars4Compare;
