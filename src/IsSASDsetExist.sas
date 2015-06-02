/*
    Program Name: IsSASDsetExist.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date:2013/12/12

*/

%macro IsSASDsetExist(indata);

    %let _exist = %sysfunc(exist(&indata));

%mend IsSASDsetExist;
