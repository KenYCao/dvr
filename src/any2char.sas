/*
    Program Name: any2char.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/01/16
*/

*
*
<--
1. Ken on 2013/02/06: If character variable, then format will not be used.
-->
*;

%macro any2char(invar =, indata =);
    %local dsid;
    %local rc;
    
    %local vartype;
    %local varnum;
    %local varfmt; 

    %getvarinfo
    (
        indata = &indata,
        invar = &invar,
        getvarnum = Y,
        getvarfmt = Y,
        getvartype = Y
    );

    length _charval $200;

    %if &vartype = C %then _charval=&invar;
    %else %if &vartype=N and &invar=. %then _charval = ' ';
    %else 
        %do;
            %if %length(&varfmt)>0 %then 
                %do;
                    _charval = strip(put(&invar, &varfmt));
                %end;
            %else
                %do;
                    _charval=strip(put(&invar, best.));
                %end;
         %end;
%mend any2char;
