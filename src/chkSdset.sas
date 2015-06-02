/*
    Program Name: chkSdset.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/25
    
    Check value of source dataset column.
*/

%macro chkSdset(indata=, masterData=);

    data _null_;
        length ssdset $32;
        if _n_ = 1 then do;
            declare hash h (dataset:"&masterData");
            rc = h.defineKey('ssdset');
            rc = h.defineDone();
            call missing(ssdset);
        end; 
        set &indata;
        sdset = compress(sdset, ,'kw');
        sdset = translate(sdset, " ", "&dlm4sdset");
        sdset = strip(compbl(sdset));
        if sdset = ' ' then do;
            call symput('isErr', '1');
            put 'ERR' 'OR: Source dataset for issue ' issueid " missing";
            return;
        end;
        nsdset = countc(strip(sdset), " ") + 1;
        do i = 1 to nsdset;
            ssdset = upcase(scan(strip(sdset), i, " "));
            rc = h.find();
            if rc > 0 then do;
                put "ERR" "OR: Source dataset " ssdset " for issue " issueid " not found in source dataset worksheet in configuration file.";
                call symput('IsErr', '1');
            end;
        end;
    run;

%mend chkSdset;
