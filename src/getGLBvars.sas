/*
    Program Name: getGLBvars.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/11

    Get global variables for a issue
*/


%macro getGLBvars(issueID);

    data _null_;
        set &dvpConfigDset;
        where upcase(issueid) = strip("%upcase(&issueID)");

        length _ALLGLBvars $1024;
        array glbv{*} glbvar:;
        do i = 1 to dim(glbv);
            if glbv[i] = ' ' then continue;
            _ALLGLBvars = strip(_ALLGLBvars) || ' ' || glbv[i];
        end;
        call symput('glbvars', strip(upcase(_ALLGLBvars)));
    run;


%mend getGLBvars;
