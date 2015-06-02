/*
    Program Name: CHKrefConfig.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/23
        
    Check reference dataset.
*/




%macro CHKrefConfig(config);

    * check availability of reference source dataset;
    data _CHKrefConfig0;
        set &config;
        length refdset $32 IsDataExist $1;
        do i = 1 to nrefdset;
            refdset = strip(upcase(scan(refdsets, i, " ")));
            __dsid  = open("&sourceLibrf"||'.'||refdset);
            if __dsid = 0 then do;
                call symput('IsErr', '1');
                IsDataExist = 'N';
                put "ERR" "OR: Reference dataset: " refdset " for issue " issueid " not found in source data directory &sdatadir";
            end;
            else IsDataExist = 'Y';
            __rc = close(__dsid);
            output;
        end;
        keep issueid refdsets refdset nrefdset IsDataExist nrefvar kdflag refvars;
    run;


    * check availability of reference variable;
    data _CHKrefConfig1;
        set _CHKrefConfig0;
        length refdset $32 __refvar $65 __refdset $32;
        if IsDataExist = 'N' then return;
        if nrefvar = 0 then return;

        * in case of return statement is executed;
        retain __dsid; 
        if _n_ > 1 then do;
            rc = close(__dsid);
        end;

        __dsid = open("&sourceLibrf.."||refdset);

        /* 
            If Reference Variable column is left blank, then put an w a r n i n g message (all variables in referenced dataset(s)
            will be kept.)
        */
        if nrefvar = 0 then do;
            put "WARN" "ING: Column Reference Variable is left blank. All variables in reference dataset(s) will be kept.";
        end;
        /*
            If referenced single dataset:
            1. check if referenced dataset name is correct as referenced dataset (when user use DATASET-NAME.VARIABLE-NAME format).
            2. check if referenced variable exists in referenced dataset.
        */
        else if nrefdset = 1 then do j = 1 to nrefvar;
            __refvar = strip(scan(refvars, j, " "));
            /*
                if DATASET-NMAME.VARIABLE-NAME format
            */
            if index(__refvar, '.') > 0 then do;
                __refdset = upcase(strip(scan(__refvar, 1, '.')));
                /* 
                    incorrect DATASET-NAME (maybe typo);
                */
                if __refdset ^ = refdset then do;
                    put "ERR" "OR: Issue: " issueid ". Reference variable " __refvar " referenced dataset " __refdset " which was not found in"
                        " Reference Ddataset " refdsets;
                    call symput('IsErr', '1');
                end;
                /*
                    incorrect VARAIBLE-NAME
                */
                else do;
                    __varnum = varnum(__dsid, strip(scan(__refvar, 2, '.'))); 
                    if __varnum = 0 then do;
                        put "ERR" "OR: Issue: " issueid ". Reference variable " __refvar " not found in referenced dataset " refdset;
                        call symput('IsErr', '1');
                    end;
                end;
            end;
            else do; /* if VARIABLE-NAME format*/
                put __refvar=;
                __varnum = varnum(__dsid, strip(__refvar)); 
                 /*
                    incorrect VARAIBLE-NAME
                */
                if __varnum = 0 then do;
                    put "ERR" "OR: Issue: " issueid ". Reference variable " __refvar " not found in referenced dataset " refdset;
                    call symput('IsErr', '1');
                end;
            end;
        end;
        else do j = 1 to nrefvar;
            __refvar = strip(scan(refvars, j, " "));
            /* when multiple datasets are referenced, a reference variable must use DATASET-NAME.VARIABLE-NAME format */
            if index(__refvar, '.') = 0 then do;
                put "WARN" "ING: Issue: " issueid ". Inva" "lid syntax of reference variable: " __refvar;
                put "ERR" "OR: You must use DATASET-NAME.VARIABLE-NAME format when referenced multiple datasets";
                call symput('IsErr', '1');
            end;
            else do;
                __refdset = strip(scan(__refvar, 1, '.'));
                if findw(refdsets, strip(__refdset)) = 0 then do; /* incorrect DATASET-NAME*/
                    put "ERR" "OR: Issue: " issueid ". Reference variable " __refvar "referneced dataset " __refdset
                        " not found in Referenced Dataset column: " refdsets;
                    call symput('IsErr', '1');
                end;
                else if __refdset ^= refdset then return;
                else do;
                    __varnum = varnum(__dsid, strip(scan(__refvar, 2, '.'))); 
                    if __varnum = 0 then do; /* incorrect VARIABLE-NAME */
                        put "ERR" "OR: Issue: " issueid ". Reference variable " __refvar " not found in referenced dataset " refdset;
                        call symput('IsErr', '1');
                    end;
                end;
            end;
        end;
        __rc = close(__dsid);
        keep issueid nrefdset nrefvar refdset refvars kdflag;
    run;

%mend CHKrefConfig;
