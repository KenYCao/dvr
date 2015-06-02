/*
    Program Name: dvpNormalize.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/12/12
*/


/*************************************************************************************
REVISION HISTORY

2014/03/10 Ken Cao: Add a blank column Q2COMMENT in the end.
2014/03/27 Ken Cao: Bug fix: forgot to keep global variables.
*************************************************************************************/


%macro dvpNormalize();


    %local maxKeyVarNum;
    %local maxRepVarNum;

    %local allIssueList;
    %local nIssue;
    %local i;
    %local issueDset;
    %local j;

    %local glbvars;
    %local nKeyvar;
    %local nRepvar;
    %local glbvcnt;

    %getMaxKeyVarNum;
    %getMaxRepVarNum;

    %do i = 1 %to &maxKeyVarNum;
        %local keyvar&i;
    %end;

    %do i = 1 %to &maxRepVarNum;
        %local repvar&i;
    %end;


    data _dvpAllIssue0;
        length issueid $32;
        if 0;
        call missing(issueid);
    run; 

    %getIssueList(&dvpConfigDset(where=(nobs>0)));

    /*initial value*/
    %let maxKeyvar = 0; 
    %let maxRepvar = 0;

    %do i = 1 %to &nIssue;

        %let issueDset = %scan(&allIssueList, &i, " ");
        
        data _null_;
            set &dvpConfigDset;
            where issueid = "&issueDset";
            array keyv{*} keyvar:;
            array repv{*} repvar:;
            do i = 1 to dim(keyv);
                if keyv[i] = ' ' then leave; 
                call symput('keyvar'||strip(put(i, best.)), strip(keyv[i]));
            end;
            do i = 1 to dim(repv);
                if repv[i] = ' ' then leave;
                call symput('repvar'||strip(put(i, best.)), strip(repv[i]));
            end;
            call symput('glbvars', strip(globalvars));
            call symput('nkeyvar', strip(put(nkey, best.)));
            call symput('nrepvar', strip(put(nrep, best.)));
        run;

        data _norm0;
            set &pdatalibrf..&issueDset;
            where __deleted = ' ';
            length issueid $32;
            issueid = "&issueDset";
            %do j = 1 %to &nKeyvar;
                length keyvar_&j $200;
                %any2char(invar = &&keyvar&j, indata = &pdatalibrf..&issueDset);
                keyvar_&j = _charVal;
                keep keyvar_&j;
            %end;
            %do j = 1 %to &nRepvar;
                length repvar_&j $200;
                %any2char(invar = &&repvar&j, indata = &pdatalibrf..&issueDset);
                repvar_&j = _charVal; 
                keep repvar_&j;
            %end;
            keep &glbvars issueid __recid __q2cmnt;
            %if &compare = Y %then keep _diff_ _type_;;
        run;

        data _dvpAllIssue0;
            set _dvpAllIssue0 _norm0;
        run;

        %do j = 1 %to &nkeyvar;
            %let keyvar&j = ;
        %end;

        %do j = 1 %to &nrepvar;
            %let repvar&j = ;
        %end;

    %end;

    * mockup dataset ;
    data _struct; 
        set &dvpConfigDset;
        where nobs > 0;
        %do i = 1 %to &maxKeyVarNum;
            length keyvlbl_&i $300;
            if keyvar&i > ' ' then
                do;
                    keyvlbl_&i = strip(keyvar&i)||'('||strip(keyvlbl&i)||')';
                    %if &displayVarName = N %then keyvlbl_&i = scan(keyvlbl_&i, 2, '()');
                    %else %if &displayVarLabel = N %then keyvlbl_&i = scan(keyvlbl_&i, 1, '()');
                end;
            keep keyvlbl_&i;
        %end;
        %do i = 1 %to &maxRepVarNum;
            length repvlbl_&i $300;
            if repvar&i > ' ' then
                do;
                    repvlbl_&i = strip(repvar&i)||'('||strip(repvlbl&i)||')';
                    %if &displayVarName = N %then repvlbl_&i = scan(repvlbl_&i, 2, '()');
                    %else %if &displayVarLabel = N %then repvlbl_&i = scan(repvlbl_&i, 1, '()');
                end;
            keep repvlbl_&i;
        %end;
        keep issueid message issuetyp sdset sdsetlbl ;
    run;


    %stripCompbl(globalvars, &globalvars);

    %let glbvcnt = %sysfunc(ifc(%length(&globalvars) = 0, -1, %eval(%sysfunc(countc(&globalvars, @)) + 1)));

    %do i = 1 %to &glbvcnt;
        %local glbvar&i;
        %let glbvar&i   = %upcase(%scan(%scan(&globalvars, &i, @), 1, %str(())));
    %end;

    data _dvpAllIssueNM;
        retain 
            _type_ _diff_ __recid 
           issueid message issuetyp sdset sdsetlbl
            %do i = 1 %to &glbvcnt;
                &&glbvar&i 
            %end;
            %do i = 1 %to &maxKeyVarNum;
                keyvlbl_&i keyvar_&i 
            %end;
            %do i = 1 %to &maxRepVarNum;
                repvlbl_&i repvar_&i 
            %end;
            __q2cmnt
        ;
        keep 
            _type_ _diff_ __recid 
           issueid message issuetyp sdset sdsetlbl
            %do i = 1 %to &glbvcnt;
                &&glbvar&i 
            %end;
            %do i = 1 %to &maxKeyVarNum;
                keyvlbl_&i keyvar_&i 
            %end;
            %do i = 1 %to &maxRepVarNum;
                repvlbl_&i repvar_&i 
            %end;
            __q2cmnt
        ;
        merge _dvpAllIssue0 _struct;
            by issueid;

        %if &compare = N %then 
            %do;
                length _type_ $1 _diff_ $32767;
                call missing(_type_, _diff_);
            %end;

    run;

%mend dvpNormalize;
