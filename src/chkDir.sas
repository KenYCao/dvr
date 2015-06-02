/*
    Program Name: chkDir.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/12/11
*/

%macro chkDir(dir,suppressErrMsg); /*check validity of input directory/file */
    
    %local blank;
    %local rc;

    %let blank = ;
    %let rc = %sysfunc(fileexist(&dir));
    
    %if &rc = 0 %then 
        %do;
            %let IsErr = 1;
            %if %upcase(&suppressErrMsg) ^= Y %then %put ERR&blank.OR: &dir not exists;
        %end;
 
%mend chkDir;

