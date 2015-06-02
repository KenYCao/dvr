/*
    Program Name: chkIssueMSG.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/25

    Check issue message
*/


%macro chkIssueMSG(indata);
    data _null_; 
        set &indata;
        if message  = '' then do;
            put 'ERR'  "OR: Message of issue " issueid "is missing." ;
            call symput('IsErr', '1');
        end;
    run;
%mend chkIssueMSG;
