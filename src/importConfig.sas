/*
    Program Name: importConfig.sas
        @Author: Ken Cao(yong.cao@q2b.com)
        @Initial Date: 2013/12/12

    Import and validate configuration file.

    REVISION HISTORY:
    2014/03/18 Ken Cao: Add a variable rptvar2comp (variables to be compared in macro %dvpIssueDsetCompare).
    2014/07/03 Ken Cao: Add a new worksheet "layout3" for generating layout 3 report.
    2015/04/03 Ken Cao: Fix a bug when key variables and report variables in configuration file are overlapped.
*/


%macro importConfig(configdir, configfn);

    %local glbvcnt;
    %local i;
    %local maxRefDset;


    /********************************************************************************************************************
    * returns 4 datasets;
    * 1: _config (contains key/report variables for each issue id)
    * 2: _issList (contains meta data for each issue id: issue type / message / reference dataset(s) / reference variables
    * 3: _sourceDsets (contains source dataset information)
    * 4: _AllissueType0 (contains all issue types)
    * 5. _L3config0 (configuration for layout 3 reports).
    ********************************************************************************************************************/
    %readconfig_vbs
    (
        configdir = &configdir,
        configfn  = &configfn
    );


    * combine config and issue list together;
    proc sort data = _config;  by issueid; run;
    proc sort data = _isslist; by issueid; run;

    data _dvpConfig0;
        merge _config(in = a rename = (linenum = linenum1)) _isslist(rename = (linenum = linenum2));
            by issueid;
        if a;
        length message $1024 issueTyp $255;
        %if &reviewonly = Y %then %do;
        message  = msgr;
        issueTyp = issueTypR;
        %end;
        %else %do; 
        /* if msgd is null, use msgr instead */
        message  = coalescec(msgd, msgr);
        issueTyp = coalescec(issueTypD, issueTypR);
        ;
        %end;
        drop msgr msgd issueTypR issueTypD;
    run;


    %chkIssueID(_dvpConfig0);
    %chkIssueMSG(_dvpConfig0);
    %chkVars(_dvpConfig0);
    %chkSdset(indata=_dvpConfig0, masterdata=_sourceDsets);

    %if &IsErr = 1 %then %return;

    data _dvpConfig1;
        length ssdset $32 ssdsetlbl $255;
        if _n_ = 1 then do;
            declare hash h (dataset:"_sourceDsets");
            rc = h.defineKey('ssdset');
            rc = h.defineData('ssdsetlbl');
            rc = h.defineDone();
            call missing(ssdset, ssdsetlbl);
        end; 
        set _dvpConfig0;
        sdset = compress(sdset, ,'kw');
        sdset = translate(sdset, " ", "&dlm4sdset");
        sdset = strip(compbl(sdset));
        nsdset = countc(strip(sdset), " ") + 1;
        length sdsetlbl $2048;
        call missing(sdsetlbl);
        do i = 1 to nsdset;
            ssdset = upcase(scan(strip(sdset), i, " "));
            rc = h.find();
            if rc = 0 then 
            sdsetlbl = ifc(sdsetlbl = ' ', ssdsetlbl, strip(sdsetlbl)||'0A'x||ssdsetlbl);
        end;
        sdset = tranwrd(strip(sdset), ' ', ', ');
        drop rc ssdsetlbl ssdset i nsdset;
    run;
    
    proc sort data = _dvpConfig1; by issueid; run;

    
    /*Global Variable*/
    %let glbvcnt = %sysfunc(ifc(%length(&globalvars) = 0, -1, %eval(%sysfunc(countc(&globalvars, @)) + 1)));

    %do i = 1 %to &glbvcnt;
        %local glbvar&i;
        %local glbvlbl&i;
        %let glbvar&i   = %upcase(%scan(%scan(&globalvars, &i, @), 1, %str(())));
        %let glbvlbl&i  = %nrbquote(%scan(%scan(&globalvars, &i, @), 2, %str(())));
    %end;




    data _dvpConfig2;
        set _dvpConfig1;
        
        * open issue dataset in output library;
        __dsid   = open("&pdatalibrf"||'.'||strip(issueid));

        * if dataset cannot be opened -- dataset not existed in output library - stop processing current record;
        if __dsid = 0 then return;



       * flag variable that indicates whether the data is in library &pdatalibrf;
        __IsDataExist = 'Y';



        **********************************************************************************************;
        * global variables --> variables that would not be tranposed;
        **********************************************************************************************;

        length glbvar1 - glbvar&glbvcnt $32 glbvlbl1 - glbvlbl&glbvcnt $256 _glbvlbl $255;
        array glbvar{*} glbvar:;
        array glbvlbl{*} glbvlbl:;
        nglb = 0; /* # of actual global variables */
        %do i = 1 %to &glbvcnt;
           __varnum   = varnum(__dsid, "&&glbvar&i");
            if __varnum > 0 then 
                do;
                    nglb          = nglb + 1;
                    glbvar[nglb]  = "&&glbvar&i";
                    glbvlbl[nglb] = "%bquote(&&glbvlbl&i)";
                    _glbvlbl      = varlabel(__dsid, __varnum);
                    glbvlbl[nglb] = coalescec(glbvlbl[nglb], _glbvlbl, upcase(glbvlbl[nglb]));
                end;
        %end;

        * concatenate all global variables;
        length globalvars $256 ;
        do i = 1 to dim(glbvar);
            if glbvar[i] = ' ' then continue;
            globalvars  = ifc(globalvars > ' ', strip(globalvars)||' '||glbvar[i], glbvar[i]);
        end;

        globalvars = upcase(globalvars);


        **********************************************************************************************;
        * key variabels;
        **********************************************************************************************;

        length keyvar1 - keyvar&nkeyvcol $32 keyvlbl1 - keyvlbl&nkeyvcol $256 key4comp _key4comp $1024 key4display $1024;

        * original key variable names in the configuration file;
        array orgkey{*} key1 - key&nkeyvcol;

        * clean variable name and variable label;
        array newkey{*} keyvar1 - keyvar&nkeyvcol;
        array newklbl{*} keyvlbl1 - keyvlbl&nkeyvcol;

        n = 0;
        nkey = 0; /* # of actual key variables (to be transposed)*/ 

        length _keyvname $32 _keyvlbl _actklbl $256;

        do i = 1 to dim(orgkey);
            * if org[i] is null then exit current iteration;
            if orgkey[i] = ' ' then continue;

            * clean variable name and label;
            _keyvname = strip(upcase(scan(orgkey[i], 1, '()*')));
            _keyvlbl  = strip(scan(orgkey[i], 2, '()*'));

            * concatenate all key variables;
            key4comp = ifc(key4comp > ' ', strip(key4comp)||' '||_keyvname, _keyvname);
           
            * if key variables is marked with asterisk then the variable is used for compare only; 
            * and other variables (not marked with asterisk) will be used for display only;
            * if no key variable is marked with asterisk then all key variables will be used for compare;
            * if key variable is an global variable then it will not be used for display;
            if index(orgkey[i], '*') > 0 then _key4comp = ifc(_key4comp > ' ', strip(_key4comp)||' '||_keyvname, _keyvname);
            else if findw(globalvars, _keyvname) = 0 then
                do;
                    n          = n + 1; 
                    nkey       = n;
                    newkey[n]  = _keyvname;
                    newklbl[n] = _keyvlbl;
                    __varnum   = varnum(__dsid, _keyvname);
                    * no need to check if __varnum > 0 since variable passed CHKconfig;
                    * actual label;
                    _actklbl   = varlabel(__dsid, __varnum);
                    * DISPLAY LABEL: user customized label >> variable original label >> variable name ;
                    newklbl[n] = coalescec(newklbl[n], _actklbl, _keyvname);
                    key4display = ifc(key4display > ' ', strip(key4display)||' '||_keyvname, _keyvname);
                end;
            call missing(_keyvname, _keylbl, _actlbl);
        end;

        key4comp    = coalescec(_key4comp, key4comp);
        key4comp    = upcase(key4comp);
        key4display = upcase(key4display);
        drop _key4comp;

        

        **********************************************************************************************;
        * report variables
        **********************************************************************************************;

        length repvar1 - repvar&nrepvcol $32 repvlbl1 - repvlbl&nrepvcol $256 rptvars $1024;

        * original report variables;
        array orgrep{*} rep1 - rep&nrepvcol;

        * clean report variables and labels;
        array newrep{*} repvar1 - repvar&nrepvcol;
        array newrlbl{*} repvlbl1 - repvlbl&nrepvcol;

        n = 0;
        nrep = 0; /* # of actual report variables (to be transposed)*/ 

        length _repvname $32 _repvlbl _actrlbl $256;


        do i = 1 to dim(orgrep);
            if orgrep[i] = ' ' then continue;

            * clean variable name;
            _repvname = strip(upcase(scan(orgrep[i], 1, '()')));
            _repvlbl  = strip(scan(orgrep[i], 2, '()'));

            rptvars          = ifc(rptvars > ' ', strip(rptvars)|| ' '||_repvname, _repvname);
            /* Exclude GLOBALVARS and KEYVARS from report variables */
            if findw(globalvars, upcase(strip(_repvname))) > 0 then continue;
            if findw(key4display, upcase(strip(_repvname))) > 0 then continue;
            nrep       = nrep + 1;
            n          = n + 1;
            newrep[n]  = _repvname;
            newrlbl[n] = _repvlbl;
            __varnum   = varnum(__dsid, _repvname);
            * no need to check if __varnum > 0 since variable passed CHKconfig;
            _actrlbl   = varlabel(__dsid, __varnum);
            * DISPLAY LABEL: user customized label >> variable original label >> variable name ;
            newrlbl[n] = coalescec(newrlbl[n], _actrlbl, _repvname);

        end;

        rptvars = upcase(rptvars);


        **********************************************************************************************;
        * variables for compare
        **********************************************************************************************;

        length rptvars2comp $1024;
        rptvars2comp = rptvars;


        do i = 1 to dim(newkey);
            if findw(upcase(key4comp), strip(upcase(newkey[i]))) = 0 then rptvars2comp = strip(rptvars2comp) || ' ' ||newkey[i];
        end;

        do i = 1 to dim(glbvar);
            if findw(strip(upcase(key4comp)), strip(upcase(glbvar[i]))) = 0 
            and findw(upcase(rptvars2comp), strip(upcase(glbvar[i]))) = 0 then
            rptvars2comp = strip(rptvars2comp) || ' ' ||glbvar[i];
        end;



        ********************************************;
        * total # of report variables;
        ********************************************;
        nvar = nglb + nkey + nrep;


        * close opened dataset;
        __rc = close(__dsid);

        
        keep issueid nvar issueTyp sdset sdsetlbl message linenum1 linenum2 __IsDataExist
             key4comp rptvars globalvars rptvars2comp nkey nrep nglb
             glbvar: glbvlbl: keyvar: keyvlbl: repvar: repvlbl:
        ;
    run;


    /*
    * get # of records that are not marked as deleted;
    %getNOBStbl(_dvpConfig2(where=(__IsDataExist='Y')));

    proc sort data = &NOBStbl; by issueid; run;
    
    data _dvpConfig3;

        merge _dvpConfig2(in = a)
              &NOBStbl(in = b)
        ;
        by issueid;


        if not b then nobs = 0;
    run;
    */

    data _dvpConfig3;
        set _dvpConfig2;
        nobs = getnobs("&pdatalibrf"||'.'||strip(issueid)); /* will be updated after __deleted is updated*/
    run;

    /*
    data issueType;
        length issueTyp $40  issueTypn 8 allIssueType $256;
        allIssueType = "&allIssueType";
        i = 1;
        do while (scan(allIssueType, i, '@') > ' ');
            issueTyp = upcase(scan(allIssueType, i, '@'));
            issueTypn = i;
            i         = i + 1;
            output;
        end;
        keep issueTyp issueTypn;
    run;

    proc sort data = issueType;   by issueTyp; run;
    proc sort data = _dvpConfig3; by issueTyp; run;



    data _dvpConfig4;
        
        retain issueid nvar issueTypn issueTyp sdset sdsetlbl message key4comp rptvars globalvars rptvars2comp nkey nrep nglb
               nobs __IsDataExist keyvar1 - keyvar&nkeyvcol keyvlbl1 - keyvlbl&nkeyvcol repvar1 - repvar&nrepvcol repvlbl1 - repvlbl&nrepvcol
               glbvar1 - glbvar&glbvcnt glbvlbl1 - glbvlbl&glbvcnt linenum1 linenum2 ;

        keep  issueid nvar issueTypn issueTyp sdset sdsetlbl message key4comp rptvars globalvars rptvars2comp nkey nrep nglb
               nobs __IsDataExist keyvar1 - keyvar&nkeyvcol keyvlbl1 - keyvlbl&nkeyvcol repvar1 - repvar&nrepvcol repvlbl1 - repvlbl&nrepvcol
               glbvar1 - glbvar&glbvcnt glbvlbl1 - glbvlbl&glbvcnt linenum1 linenum2 ;

        merge _dvpConfig3 issueType;
            by issueTyp;

    run;
    */


    data _dvpConfig4;
        retain issueid nvar issueTyp sdset sdsetlbl message key4comp rptvars globalvars rptvars2comp nkey nrep nglb
               nobs __IsDataExist keyvar1 - keyvar&nkeyvcol keyvlbl1 - keyvlbl&nkeyvcol repvar1 - repvar&nrepvcol repvlbl1 - repvlbl&nrepvcol
               glbvar1 - glbvar&glbvcnt glbvlbl1 - glbvlbl&glbvcnt linenum1 linenum2 ;
        keep  issueid nvar issueTyp sdset sdsetlbl message key4comp rptvars globalvars rptvars2comp nkey nrep nglb
               nobs __IsDataExist keyvar1 - keyvar&nkeyvcol keyvlbl1 - keyvlbl&nkeyvcol repvar1 - repvar&nrepvcol repvlbl1 - repvlbl&nrepvcol
               glbvar1 - glbvar&glbvcnt glbvlbl1 - glbvlbl&glbvcnt linenum1 linenum2 ;
        set _dvpConfig3;
    run;

    proc sort data = _dvpConfig4 out = &dvpconfigdset; 
        by issueid;
    run;


    /************************************************************************
        Reference configuration dataset
    ************************************************************************/
    data _refConfig0;
        set _dvpConfig1(keep=issueid refdsets refvars);
        where refdsets > ' ';
        * reference datasets;
        refdsets = translate(refdsets, ' ', "&dlm4refdset");
        refdsets = strip(compbl(upcase(refdsets)));
        nrefdset = countc(strip(refdsets), " ") + 1;
        * reference variables;
        refvars  = translate(refvars, ' ', "&dlm4refvar");
        refvars  = strip(compbl(upcase(refvars)));
        * keep/drop flag (K/D);
        length kdflag $1;
        if substr(refvars, 1, 2) = 'K:' then kdflag = 'K';
        else if substr(refvars, 1, 2) = 'D:' then kdflag = 'D';
        * remove indicator from reference variable column;
        refvars  = strip(substr(refvars, 3));
        if refvars = ' ' then nrefvar = 0;
        else nrefvar = countc(strip(refvars), " ") + 1;
    run;

    %CHKRefConfig(_refConfig0);
    %if &IsErr = 1 %then %return;


    data _refConfig1;
        set _refConfig0(rename=(refvars = in_refvars nrefvar = in_nrefvar));
        length refdset $32 refvars $32767 __refvar $65;
        do i = 1 to nrefdset;
            refdset = strip(scan(strip(refdsets), i, ' '));
            if in_nrefvar = 0 then do;
                __dsid = open("&sourceLibrf.."||refdset);
                __nvar = attrn(__dsid, 'nvars');
                do j = 1 to __nvar;
                    refvars = strip(refvars)||' '||varname(__dsid, j);
                end;
                kdflag = 'K';
                __rc = close(__dsid);
            end;
            else do j = 1 to in_nrefvar;
                __refvar = strip(scan(in_refvars, j, " "));
                if index(__refvar, '.') = 0 then refvars = strip(refvars)||' '||strip(__refvar);
                else if strip(scan(__refvar, 1, '.')) = refdset then refvars = strip(refvars)||' '||scan(__refvar, 2, '.');
            end;
            refvars = strip(refvars);
            nrefvar = countc(strip(refvars), " ") + 1;
            output;
            call missing(refvars, nrefvar);
        end;
        
        keep issueid refdsets nrefdset refdset nrefvar refvars kdflag;
    run;

    data &dvpRefConfigDset;
        retain issueid refdsets nrefdset refdset nrefvar refvars kdflag;
        keep   issueid refdsets nrefdset refdset nrefvar refvars kdflag;
        set _refConfig1;
    run;



    /************************************************************************
        ALL Issue Type
    ************************************************************************/
    data _AllissueType1;
        set _AllissueType0;
        if _n_ = 1 then issueTypn = 10;
        else issueTypn + 1;
    run;


    proc sort data = &dvpConfigDset out=_AllissueType2(keep=issueTyp issueID);
        by issueTyp issueID;
    run;

    proc sort data = _AllissueType1;
        by issueTyp;
    run;

    data _null_;
        merge _AllissueType1(in=a) _AllissueType2(in=b);
            by issueTyp;
        issueTyp = strip(issueTyp);
        issueID  = strip(issueID);
        if not a then do;
            put "WARN" "ING: Issue type " issueTyp " of Issue ID " issueID " not appeared in Issue_Type worksheet of configuration file";
        end;
        else if not b and hide ^= 'Y' then do;
            put "WARN" "ING: Issue type " issueTyp " is not associated with any issue ID." "Hide this issue type in configuration file" 
               "if you do not want to display it";
        end;
        else if b and hide = 'Y' then do;
            put "WARN" "ING: Issue Type " issueTyp " is associated with at least one issue ID and should not be hided.";
        end;
    run;

    proc sort data = _AllissueType2 out = _AllissueType3(keep=issueTyp) nodupkey;
        by issueTyp;
    run;

    data _ALLissueType4;
        merge _AllissueType1(in=a) _AllissueType3(in=b);
            by issueTyp;
        if b and hide = 'Y' then hide = ' ';
        if hide = 'Y' then delete;
        if not a then issueTypn = 999;
    run;

    proc sort data = _ALLissueType4; by issueTypn issueTyp; run;

    data _ALLissueType5;
        set _ALLissueType4(drop=issueTypn) end = _eof_;
        issueTypn + 1;
        length _allIssueType_ $32767;
        retain _allIssueType_;
        if _n_ = 1 then _allIssueType_ = strip(issueTyp);
        else _allIssueType_ = strip(_allIssueType_)||'@'||strip(issueTyp);
        if _eof_ then call symput('allIssueType', strip(_allIssueType_));
    run;

    data &dvpALLissueTypeDset;
        retain issueTyp issueTypn alterText;
        keep issueTyp issueTypn alterText;
        set _ALLissueType5;
    run;

    /******************************************************************************
        get numeric issue type code into DVPCONFIGDSET from DVPALLISSUETYPEDSET
    ******************************************************************************/
    proc sql;
        alter table &dvpconfigdset
        add issueTypn num;

        update &dvpconfigdset as a
        set issueTypn = (
        select b.issueTypn
        from &dvpALLissueTypeDset as b
        where a.issueTyp = b.issueTyp
        );
    quit;



    /******************************************************************************
     2014/07/03: Configurtion for layout 3 reports
    ******************************************************************************/

    %if &layout3 = Y %then %do;
    
        * Check key variables;
        data _null_;
            set _L3config0;
            /*
            if keyvars = " " then do;
                put "ERR" "OR: Key variables for issue ID " issueid " in layout3 worksheet is missing";
                call symput('IsErr', '1');
                return;
            end;
            */
            if keyvars = ' ' then nkeyvar = 0;
            else nkeyvar = countc(strip(keyvars), " ") + 1;
            length keyvar $32;
            do i = 1 to nkeyvar;
                keyvar = scan(keyvars, i, " ");
                rc     = chkvar(strip(keyvar), "&pdatalibrf.."||strip(issueid));
                if rc = 0 then do;
                    put "ERR" "OR: Key variable " keyvar "for issue ID " issueid " in worksheet layout3 is not existed"
                        " in issue dataset";
                end;
            end;
        run;


        * check issue findings;
        data _null_;
            set _L3config0;
            pid = prxparse('/(<\w+>)/');
            startpos = 1;
            len      = 0;
            /*
            __finding  = prxchange('s/\\</[/', -1, __finding);
            __finding  = prxchange('s/\\>/]/', -1, __finding);
            */
            /*if prxmatch(pid, __finding) > 0 then */
            do while (prxmatch(pid, __finding) > 0);
                call prxposn (pid, 1, startpos, len);
                varname = substr(__finding, startpos+1, len-2);
                __finding = substr(__finding, startpos+len);
                rc2     = chkvar(strip(varname), "&pdatalibrf.."||strip(issueid));
                if rc2 = 0 then do;
                    put "ERR" "OR: Variable " varname "in findings for issue ID " issueid " in worksheet layout3 is not existed"
                        " in issue dataset";
                    call symput('IsErr', '1');
                end;
            end;
        run;

        %if &IsErr = 1 %then %return;

        * generate final dataset;
        data _L3config1;
            length issueid $32 sdset $200 sdsetlbl $2048 issueTyp $255 issueTypn 8;
            if _n_ = 1 then do;
                declare hash h (dataset:"&dvpconfigdset");
                rc = h.defineKey("issueid");
                rc = h.defineData("sdset", "sdsetlbl", "issueTyp", "issueTypn");
                rc = h.defineDone();
                call missing(issueid, sdset, sdsetlbl, issuetyp, issuetypn);
            end;
            set _L3config0;
            rc = h.find();
        run;

        data _L3config;
            retain issueid sdset keyvars sdsetlbl fieldname __finding issueTyp issueTypn; 
            set _L3config1;
            keep issueid sdset keyvars sdsetlbl fieldname __finding issueTyp issueTypn;
        run;

    %end;

%mend importConfig;
