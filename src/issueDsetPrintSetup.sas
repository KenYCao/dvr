/*
    Program Name: issueDsetPrintSetup.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/16

    drop unncessary variables.
*/

%macro issueDsetPrintSetup(indata=, issueID=, out=, outFlyOver=);

    %local dsid;
    %local blank;
    %local nobs;
    %local rc;
    /*
    %local msg;
    %local sdset;
    %local issueType;
    */
    %local keyvarNum;
    %local repvarNum;
    %local glbvarNum;
    %local nkey;
    %local nglb;
    %local nrep;
    %local i;

    %let nobs = 0;
    %let nkey = 0;
    %let nglb = 0;
    %let nrep = 0;

    %let dsid = %sysfunc(open(&indata));
    
    * cannot open dataset &issuedata;
    %if &dsid = 0 %then %do;
        %put ERR&blank.OR: Issue dataset &issueID not founds;
        %return;
    %end;


    %let nobs = %sysfunc(attrn(&dsid, nobs));
    %let rc   = %sysfunc(close(&dsid));

    * # of observations = 0;
    %if &nobs = 0 %then %do;
        %put NOTE: No observation found in issue dataset &issueID. Macro will not execute;
        %return;
    %end;

    /*
    * get issue meta information (message/source dataset/issue type);
    %getIssueMeta(&issueID, getMsg = Y, getSdset = Y, getIssueType = Y);
    */

    ******************************************************************************************;
    * Print issue dataset;
    ******************************************************************************************;
    /*
    data _null_;
        set &dvpConfigDset;
        where issueid = "&issueid";

        nkey = 0;
        nrep = 0;
        nglb = 0;

        array keyv{*} keyvar:;
        array repv{*} repvar:;
        array glbv{*} glbvar:;

        do i = 1 to dim(keyv);
            if keyv[i] > ' ' then nkey = nkey + 1;
        end;

        do i = 1 to dim(repv);
            if repv[i] > ' ' then nrep = nrep + 1;
        end;

        do i = 1 to dim(glbv);
            if glbv[i] > ' ' then nglb = nglb + 1;
        end;


        call symput('nkey', strip(put(nkey, best.)));
        call symput('nrep', strip(put(nrep, best.)));
        call symput('nglb', strip(put(nglb, best.)));
    run;
    */

    %getKeyVarNum(&issueID);
    %getRepVarNum(&issueID);
    %getGlbVarNum(&issueID);

    %let nkey = &keyvarNum;
    %let nrep = &repvarNum;
    %let nglb = &glbvarNum;

    %do i = 1 %to &nkey;
        %local keyvar&i;
        %local keyvlbl&i;
    %end;

    %do i = 1 %to &nrep;
        %local repvar&i;
        %local repvlbl&i;
    %end;

    %do i = 1 %to &nglb;
        %local glbvar&i;
        %local glbvlbl&i;
    %end;




    data _null_;
        set &dvpConfigDset;
        where issueid = "&issueid";

        array keyv{*} keyvar:;
        array keyl{*} keyvlbl:;
        array repv{*} repvar:;
        array repl{*} repvlbl:;
        array glbv{*} glbvar:;
        array glbl{*} glbvlbl:;

        j = 0;

        do i = 1 to dim(keyv);
/*            keyl[i] = prxchange('s/[""]/""/', -1, keyl[i]);*/
            if keyv[i] > ' ' then 
                do;
                    j = j + 1;
                    call symput('keyvar'||strip(put(j, best.)), strip(keyv[i]));
                    call symput('keyvlbl'||strip(put(j, best.)), strip(keyl[i]));
                end;
        end;

        j = 0;

        do i = 1 to dim(repv);
/*            repl[i] = prxchange('s/[""]/""/', -1, repl[i]);*/
            if repv[i] > ' ' then 
                do;
                    j = j + 1;
                    call symput('repvar'||strip(put(j, best.)), strip(repv[i]));
                    call symput('repvlbl'||strip(put(j, best.)), strip(repl[i]));
                end;
        end;

        j = 0;

        do i = 1 to dim(glbv);
/*            glbl[i] = prxchange('s/[""]/""/', -1, glbl[i]);*/
            if glbv[i] > ' ' then 
                do;
                    j = j + 1;
                    call symput('glbvar'||strip(put(j, best.)), strip(glbv[i]));
                    call symput('glbvlbl'||strip(put(j, best.)), strip(glbl[i]));
                end;

        end;
    run;

    data _issueDset0;
        
        * in case user specify Y for &compare and Y for &skipDataProcessing;
        * but _type_ and _diff2_ are not in data;
        length _type_ $1 _diff2_ $32767;
        call missing(_type_, _diff2_);

        set &indata;
        keep 
        __recid __q2cmnt
        %do i = 1 %to &nkey; &&keyvar&i  %end;
        %do i = 1 %to &nrep; &&repvar&i  %end;
        %do i = 1 %to &nglb; &&glbvar&i  %end;
        ;
        keep _type_ _diff2_ _mdfnum_ _diff3_; 

        length __odd $2;
        __odd = strip(put(mod(_n_, 2), best.));
        keep __odd;

        /*
        %if &reverseVarNameLBL = Y %then %do;
            %do i = 1 %to &nkey;
                label &&keyvar&i = "&odsEscapeChar.S={fontweight = bold flyover = ""&&keyvlbl&i""}&&keyvar&i";
            %end;
            %do i = 1 %to &nrep;
                label &&repvar&i = "&odsEscapeChar.S={fontweight = bold flyover = ""&&repvlbl&i""}&&repvar&i";
            %end;
            %do i = 1 %to &nglb;
                label &&glbvar&i = "&odsEscapeChar.S={fontweight = bold flyover = ""&&glbvlbl&i""}&&glbvar&i";
            %end;
        %end;
        %else %do;
            %do i = 1 %to &nkey;
                label &&keyvar&i = "&odsEscapeChar.S={fontweight = bold flyover = ""&&keyvar&i""}&&keyvlbl&i";
            %end;
            %do i = 1 %to &nrep;
                label &&repvar&i = "&odsEscapeChar.S={fontweight = bold flyover = ""&&repvar&i""}&&repvlbl&i";
            %end;
            %do i = 1 %to &nglb;
                label &&glbvar&i = "&odsEscapeChar.S={fontweight = bold flyover = ""&&glbvar&i""}&&glbvlbl&i";
            %end;
        %end;
        */
    run;


    %if %length(&outFlyover) > 0 %then %do;
    data _flyOver0;
        length varname $32 label $255 flyover $255 ord 8;
        %do i = 1 %to &nglb;
            %let glbvlbl&i = %bquote(%sysfunc(prxchange(s/[""]/""/, -1, %bquote(&&glbvlbl&i))));
            varname = "&&glbvar&i";
            %if &reverseVarNameLBL = N %then %do;
            label = "&&glbvlbl&i";
            flyover = "&&glbvar&i";
            %end;
            %else %do;
            label = "&&glbvar&i";
            flyover = "&&glbvlbl&i";
            %end;
            ord + 1;
            output;
        %end;
        %do i = 1 %to &nKey;
            %let keyvlbl&i = %bquote(%sysfunc(prxchange(s/[""]/""/, -1, %bquote(&&keyvlbl&i))));
            varname = "&&keyvar&i";
            %if &reverseVarNameLBL = N %then %do;
            label = "&&keyvlbl&i";
            flyover = "&&keyvar&i";
            %end;
            %else %do;
            label = "&&keyvar&i";
            flyover = "&&keyvlbl&i";
            %end;
            ord + 1;
            output;
        %end;
        %do i = 1 %to &nRep;
            %let repvlbl&i = %bquote(%sysfunc(prxchange(s/[""]/""/, -1, %bquote(&&repvlbl&i))));
            varname = "&&repvar&i";
            %if &reverseVarNameLBL = N %then %do;
            label = "&&repvlbl&i";
            flyover = "&&repvar&i";
            %end;
            %else %do;
            label = "&&repvar&i";
            flyover = "&&repvlbl&i";
            %end;
            ord + 1;
            output;
        %end;
    run;

    proc sort data = _flyOver0; by varname ord; run;

    data _flyOver1;
        set _flyOver0;
            by varname ord;
        if first.varname;
    run;

    proc sort data = _flyOver1 out = &outFlyOver(drop=ord);
        by ord varname;
    run;
    %end;
    

    data &out;
        retain __recID
        %do i = 1 %to &nglb; &&glbvar&i  %end;
        %do i = 1 %to &nkey; &&keyvar&i  %end;
        %do i = 1 %to &nrep; &&repvar&i  %end;
        _type_ _diff2_ __q2cmnt __odd _diff3_ _mdfnum_ 
        ;
        keep __recID
        %do i = 1 %to &nglb; &&glbvar&i  %end;
        %do i = 1 %to &nkey; &&keyvar&i  %end;
        %do i = 1 %to &nrep; &&repvar&i  %end;
        _type_ _diff2_ __q2cmnt __odd  _diff3_ _mdfnum_
        ; 
        set _issueDset0;
    run;

%mend issueDsetPrintSetup;
