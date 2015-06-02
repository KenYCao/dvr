/*
    Program Name: export2CSV.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/25

    Export SAS datasets to CSV file
    PROC EXPORT doesn't allow line feed in character string.
*/

%macro export2CSV(indata=, outfile=, lrecl=65536);
    %local rc;
    %local filrf;
    %local blank;
    %local dsid;
    %local nvar;
    %local i;
    %local rc;
    

    %let blank = ;
    %let filrf = csv;

    %let rc = %sysfunc(filename(filrf, &outfile));

    %if &rc ^= 0 %then %do;
        %put ERR&blank.OR: Invalid filename: &outfile.;;
        %return;
    %end;

    %let dsid = %sysfunc(open(&indata));
    %let nvar = %sysfunc(attrn(&dsid, nvar));
    %do i = 1 %to &nvar;
        %local varname&i;
        %local vartype&i;
        %local varlen&i;

        %let varname&i = %sysfunc(varname(&dsid, &i));
        %let vartype&i = %sysfunc(vartype(&dsid, &i));
        %let varlen&i  = %sysfunc(varlen(&dsid, &i));

        %if &&vartype&i = C %then %do;
            %let varlen&i = %eval(&&varlen&i + &&varlen&i + 2);
            %if &&varlen&i > 32767 %then %let &&varlen&i = 32767;
        %end;

        %if &&vartype&i = C %then %let vartype&i = char;
        %else %let vartype&i = num;
    %end;
    %let rc = %sysfunc(close(&dsid));

    proc sql;
        create table ___TBE(
            &varname1 &vartype1 length=&varlen1
        %do i = 2 %to &nvar;
            , &&varname&i &&vartype&i length=&&varlen&i
        %end;
        );

        insert into ___TBE
        select *
        from &indata;

    quit;


    data ___TBE;
        set ___TBE;
        array ___char{*} _character_;
        do i = 1 to dim(___char);
            if index(___char[i], ',') 
                or index(___char[i], '0A'x) 
                or index(___char[i], '0D'x)
                or index(___char[i], '"')
             then do;
                ___char[i] = '"'||strip(prxchange('s/[""]/""/', -1, ___char[i]))||'"';
             end;
        end;
        drop i;
    run;

    data _null_;
        file &filrf lrecl = &lrecl dlm=',';
        set ___tbe;
        if _n_ = 1 then do;
            put "&varname1" %do i = 2 %to &nvar; ",&&varname&i" %end;;
        end;
        put ( _all_ ) (+0);
    run;

    proc datasets lib=work nolist nodetails;
        delete ___TBE;
    quit;


    %let rc = %sysfunc(filename(filrf));
%mend export2CSV;
