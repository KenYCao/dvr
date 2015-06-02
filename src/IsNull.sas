/*
    Program Name: IsNull.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/12/11
*/



/*
    mvar: macro variable name; 
    mval: macro variable value
    defaultval: default value that will be assigned when input macro variable is null
*/

%macro IsNull(mvar, mval, defaultVal, suppressErrMsg); 
    
    %local blank;
    %local rc;

    %let blank = ;
    %let rc    = %length(&mval);

    %if &rc = 0 %then
        %do;
            %let rc = %length(&defaultVal);
            %if &rc = 0 and %upcase(&suppressErrMsg) ^= Y %then 
                %do;
                   %put ERR&blank.OR: Input macro variale %upcase(&mvar) is null.;
                   %let IsErr = 1;
                %end;
            %else
                %do;
                    %let &mvar = &defaultVal;
                    %put NOTE: Input macro variale %upcase(&mvar) is null. Default value &defaultVal will be assigned;
                %end;
        %end;

 
%mend IsNull;
