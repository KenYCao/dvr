/*
    Program Name: stripCompbl.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/02/26
*/

%macro stripCompbl(mvar, mval);
    %let &mvar = %sysfunc(prxchange(s/^\s+//, -1, &mval)); /*remove leading blanks*/
    %let &mvar = %sysfunc(prxchange(s/\s+/ /, -1, &mval)); /*replace multiple consecutive blanks as single blank*/
%mend stripCompbl;
