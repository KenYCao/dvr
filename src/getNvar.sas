/*
    Program Name: getNvar.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/23
    
    Get # of DISTINCT key variables + report variables + global variables. 
*/

%macro getNvar(issueid);
    
    * nvar should be defined as local in macro revoking macro getNvar;
    %let nvar = 0;

    data _null_;
        set &dvpConfigDset;
        where issueid = "&issueid";
        call symput('nvar', strip(put(nvar, best.)));
    run;
%mend getNvar;
