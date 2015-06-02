/*
    Program Name: getKeyVars.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/11

    Get key variables for a issue
*/


%macro getKeyVars(issueID);

    data _null_;
        set &dvpConfigDset;
        where upcase(issueid) = strip("%upcase(&issueID)");

        length _ALLkeyvars $1024;
        array keyv{*} keyvar:;
        do i = 1 to dim(keyv);
            if keyv[i] = ' ' then continue;
            _ALLkeyvars = strip(_ALLkeyvars) || ' ' || keyv[i];
        end;
        call symput('keyvars', strip(upcase(_ALLkeyvars)));
    run;


%mend getKeyVars;
