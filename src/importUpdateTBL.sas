/*
    Program Name: importUpdateTBL.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/11

    Import update table
*/


%macro importUpdateTBL(infile);

    %local filrf;
    %local rc;
    %local blank;
    %local dlm;

    %let dlm = %str(,);

    %let filrf = %str(deltbl);
    %let blank = ;
    
    %let rc = %sysfunc(filename(filrf, &infile));

    %if &rc ^= 0 %then
        %do;
            %let IsErr = 1;
            %put ERR&blank.OR: File &MasterFile could not be opened;
            %return;
        %end;

    data &updateTBL;
        informat 
            issueid $32. 
            subject $255. 
            __groupid $255.
            __recid $64. 
            __keyid $64.  
            __finding $1024.  
            __q2cmnt $1024. 
            __clientcmnt $1024. 
            __initdt $40. 
            __querystat $1024.  
            __deleted $1.
            ;
        infile &filrf lrecl = 32767 dsd dlm = "&dlm" firstobs = 2 termstr=crlf;
        input 
            issueid $ 
            subject $ 
            __groupid $ 
            __recid $ 
            __keyid $ 
            __finding $ 
            __q2cmnt $ 
            __clientcmnt $  
            __initdt $ 
            __querystat $
            __deleted $
         ;
        format 
            issueid $32. 
            subject $255. 
            __groupid $255. 
            __recid $64. 
            __keyid $64.  
            __finding $1024.  
            __q2cmnt $1024. 
            __clientcmnt $1024. 
            __initdt $40. 
            __querystat $1024. 
            __deleted $1.
        ;
        issueid   = upcase(issueid);
        __deleted = upcase(__deleted);
        /*
        * Ken on 2014/04/15: translate linefeed into inline formatting;
        __q2cmnt = tranwrd(__q2cmnt, '0D'x, "&odsEsc    apeChar.n");
        */
    run;

    %let rc = %sysfunc(filename(filrf));


    ****check update table******;

    data _null_;
        length issueid $32 __recid $64;
        if _n_ = 1 then do;
            declare hash h1(dataset:"&updateTBL");
            rc = h1.defineKey('issueid');
            rc = h1.defineDone();
            declare hash h2(dataset:"&updateTBL");
            rc = h2.defineKey('issueid', '__recid');
            rc = h2.defineDone();
            call missing(issueid, recordID);
        end;
        set &updateTBL;
        linenum = _n_;
        rc = h1.find();
        if rc ^= 0 then do;
            call symput('IsErr', '1');
            put 'ERR' 'OR: Dataset ' issueid ' in line ' linenum ' not found.';
            return;
        end;
        rc = h2.find();
        if rc ^= 0 then do;
            call symput('IsErr', '1');
            put 'ERR' 'OR: Record ID ' recordID ' in line ' linenum ' not found.';
        end;
    run;

 
%mend importUpdateTBL;
