/*
    Program Name: chkColor.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/28
    
    Check the validty of user specified colors.

*/

%macro chkColor(colorVar, colorVal, default);

    %local IsErr;
    %local blank;

    %let IsErr = 0;
    %let blank = ;

    /* to be developed */
    
    %if &IsErr = 1 %then
        %do;
            %put ERR&blank.OR: Invalid value &colorVal for &colorVar. NOT A COLOR! Default value &default will be used.;
            %let colorVar = &default;
        %end;
%mend chkColor;
