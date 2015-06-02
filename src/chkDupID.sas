/*
    Program Name: CHKdupID.sas
        @Author: Ken Cao(yong.cao@q2bi.com)
        @Initial Date: 2014/03/26

    REVISION HISTORY:
    2014/03/27 Ken Cao: Print a w-a-r-n-i-n-g message only for those whose key ID are same and record ID are not same
*/

%macro CHKdupID(suppressWarning); 

    %let suppressWarning = %sysfunc(coalescec(&suppressWarning, N));
    
    proc sql;
        create table _inValidID as
        select distinct
            issueid,
            __keyid,
            __recid
        from &md5TBL
        group by __keyid
        having count(distinct __recid) > 1
        ;
    quit;

    data _null_;
        set _inValidID end = _eof_;
        %if &suppressWarning = N %then %do;
        put "WARN" "ING: Same key id different record ID";
        put "WARN" "ING: Check records with KEY ID = " __keyid " in issue " issueid; 
        %end;
    run;
  
%mend CHKdupID;
