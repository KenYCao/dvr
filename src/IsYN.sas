/*
    Program Name: IsYN.sas
        @Author: Ken Cao(yong.cao@q2bi.com)
        @Initial Date: 2013/12/11

*/

/*
    Check if input macro variable

*/

%macro IsYN(mvar, mval, suppressErrMsg); /*mvar: macro variable name; mval: macro variable value*/
    
    %local blank;

    %if %upcase(&mval) = Y %then %let &mvar = Y;
    %else %if %upcase(&mval) = N %then %let &mvar = N;
    %else 
        %do;
            %let IsErr = 1;
            %if %upcase(&suppressErrMsg) ^= Y %then 
                %put ERR&blank.OR: Invalid value for parameter %upcase(&mvar): &mval (Y/N only!);
        %end;
    
%mend IsYN;
