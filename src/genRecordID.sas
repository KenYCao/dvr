/*
    Program Name: genRecordID.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/10

    REVISION HISOTRY

    2014/03/11 Ken Cao: Use macro %getIssueList to get all issue datasets in library &patalibrf;
    2014/03/19 Ken Cao: Add "&issueDset" when deriving record ID and Key ID.
    2014/07/04 Ken Cao: Generate Issue Finding in this step.
*/

%macro genRecordID(useMD5);
    
    %local blank;
    %local nIssue;
    %local ALLissueList;
    %local i;
    %local issueDset;
    %local keyvars;
    %local reportvars;
    %local glbvars;
    %local allvars;
    %local var;
    %local keyvars4comp;
    %local keyvar4comp;
    %local nvars;
    %local concatExpr_RecID;
    %local concatExpr_KeyID;
    %local j;
    %local varType;
    %local Expr;
    %local dlm;
    %local isIndex;


    %let blank =;

    * delimeter to separate a list of value;
    %let dlm = '01'x;
    
    %getIssueList(&dvpConfigDset(where=(__IsDataExist='Y')));

    %if %length(&useMD5) = 0 %then %let useMD5 = N;


    %do i = 1 %to &nIssue;

        %let issueDset = %upcase(%scan(&ALLissueList, &i, " "));

        %if &useMD5 = Y %then 
            %do;

                %getKeyVars(&issueDset);
                %getReportVars(&issueDset);
                %getGLBvars(&issueDset);
                %getKeyVars4Compare(&issueDset);

                *********************************************************************;
                * prepare input string for function MD5 for record ID; 
                *********************************************************************;

                %let allvars = %str(&glbvars &keyvars &reportvars);
                %let allvars = %upcase(&allvars);
                %stripCompbl(allvars, &allvars);

                %if %length(&allvars) = 0 %then
                    %do;
                        %let IsErr = 1;
                        %put ERR&blank.OR: No key/report/global variables for issue &issueDset;
                        %return;
                    %end;

                %let nvars = %sysfunc(countc(&allvars, " "));
                %let nvars = %eval(&nvars) + 1;
                
                * expression to get all variables concatenated ;
                * if a character variable, concatenate it directly;
                * if a numeric variable, concatenate it using put(  , best.);


                * Ken Cao on 2014/03/19: Add Issue ID to make _recid unique for whole database;
                %let concatExpr_RecID = strip("&issueDset");

                %do j = 1 %to &nvars;
                    %let var = %scan(&allvars, &j, " ");
                    %getVarInfo(indata = &&pdatalibrf..&issueDset, invar = &var, getvartype = Y);
                    %if %upcase(&varType) = C %then
                        %do;
                            %let Expr = ifc(&var = ' ', ' ', strip(&var));
                        %end;
                    %else
                        %do;
                            %let Expr = ifc(&var > ., strip(put(&var, best.)), ' ');
                        %end;
                    
                    %if %length(&concatExpr_RecID) = 0 %then %let concatExpr_RecID = &Expr;
                    %else %let concatExpr_RecID = %str(&concatExpr_RecID)|| &dlm || &Expr;
                %end;


                *********************************************************************;
                * prepare input string for function MD5 for key ID; 
                *********************************************************************;

                * <!-- if no key variables for compare, then use global variables --> ;
                %if %length(&keyvars4comp) = 0 %then %let keyvars4comp = &glbvars;
               
                %stripCompbl(keyvars4comp, &keyvars4comp);

                %if %length(&keyvars4comp) = 0 %then %let nvars = 0;
                %else %let nvars = %eval(%sysfunc(countc(&keyvars4comp, " ")) + 1);

                %let concatExpr_KeyID = strip("&issueDset");

                %do j = 1 %to &nvars;
                    %let keyvar4comp = %scan(&keyvars4comp, &j, " ");
                    %getVarInfo(indata = &&pdatalibrf..&issueDset, invar = &keyvar4comp, getvartype = Y);
                    %if %upcase(&varType) = C %then
                        %do;
                            %let Expr = ifc(&keyvar4comp = ' ', ' ', strip(&keyvar4comp));
                        %end;
                    %else
                        %do;
                            %let Expr = ifc(&keyvar4comp > ., strip(put(&keyvar4comp, best.)), ' ');
                        %end;
                    
                    %if %length(&concatExpr_KeyID) = 0 %then %let concatExpr_KeyID = &Expr;
                    %else %let concatExpr_KeyID = %str(&concatExpr_KeyID)|| &dlm || &Expr;
                %end;

                %if %length(&concatExpr_KeyID) = 0 %then %let concatExpr_KeyID = %str(' ');
            %end;
        

        data &pdatalibrf..&issueDset;
            
            modify &pdatalibrf..&issueDset;

            * generate record ID and key ID;
            __keyid = put(md5(&concatExpr_KeyID), $hex32.);
            __recid = put(md5(&concatExpr_RecID), $hex32.);

        run;

        
        * Ken on 2014/07/04: Generate issue finding based on configuration;
        %if &layout3 = Y %then %do;
            data &pdatalibrf..&issueDset;

                length issueid $32 __finding $1024; 
                if _n_ = 1 then do;
                    declare hash h (dataset:'_L3config');
                    rc = h.defineKey('issueid');
                    rc = h.defineData('__finding' );
                    rc = h.defineDone();
                    call missing(issueid, __finding);
                end;

                modify &pdatalibrf..&issueDset;

                issueid = "&issueDset";
                rc = h.find();
                * generate automatic __finding;
                
                length __varname $32 __value $255 __finding2 $1024;
                pid      = prxparse('/(<\w+>)/i');
                startpos = 1;
                rc       = 1;
                __finding2 = ' ';
                do while (prxmatch(pid, __finding) > 0);
                    call prxposn (pid, 1, startpos, len);
                    if startpos > 1 then __finding2  = strip(__finding2)||substr(__finding, 1, startpos-1);
                    __varname = substr(__finding, startpos+1, len-2);
                    __value   = strip(vvaluex(__varname));
                    if __value = '.' then ___value = ' ';
                    if __value = ' ' then __value = 'BLANK';
                    else __value = '"'||strip(prxchange('s/[""]/""/', -1, __value))||'"';
                    __finding2  = strip(__finding2)||' '||strip(__value);
                    __finding   = substr(__finding, startpos+len);
                end;
                __finding2 = strip(__finding2)||__finding;
                __finding  = coalescec(__finding2, __finding);
                drop __finding2 __varname __value startpos len rc pid;
            run;
        %end;

        /*
        proc sql;
            update &pdatalibrf..&issueDset
            set   
                __keyid = put(md5(&concatExpr_KeyID), $hex32.),
                __recid = put(md5(&concatExpr_RecID), $hex32.)
            ;
        quit;
        */
        
        
        ******************************************;
        * remove index before creating;
        ******************************************;
        %let isIndex = 0;
        %getDsetInfo(indata=&pdatalibrf..&issueDset, getIsIndex=Y);
        %if &isIndex = 1 %then %do;
            proc datasets library=&&pdatalibrf nodetails nolist;
                modify &issueDset;
                index delete _all_;
            quit;
        %end;

        * create index;
        proc sql noprint;
            create index __recid
            on &pdatalibrf..&issueDset(__recid);

            create index __keyid
            on &pdatalibrf..&issueDset(__keyid);

            create index __deleted
            on &pdatalibrf..&issueDset(__deleted);
        quit;
    %end;
   

%mend genRecordID;
