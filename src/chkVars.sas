/*
    Program Name: chkVars.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/25

    Check key varaibles and report variables in configuraton file.
*/


%macro chkVars(indata);

    /* Ken Cao on 2014/12/05: This DATA Step takes very long time.
    data _allIssDset0;
        set sashelp.vcolumn(keep = libname memname name);
        where libname = "%upcase(&pdatalibrf)" and upcase(memname) ^= "&md5TBL";
        length issueid $32;
        keep issueid name;
        issueid = upcase(memname);
        name    = upcase(name);
    run;
    */

    proc contents data = &pdatalibrf.._all_ 
        out = _allIssDset0(keep=memname name where=(upcase(issueid)^="&md5TBL") rename=(memname=issueid)) noprint; 
    run;


    proc sort data = &indata; by issueid; run;

    data _null_;
        length name issueid $32;
        if _n_ = 1 then do;
            declare hash h1(dataset:'_allIssDset0');
            rc1 = h1.defineKey('issueid');
            rc1 = h1.defineDone();
            declare hash h2(dataset:'_allIssDset0');
            rc2 = h2.defineKey('issueid', 'name');
            rc2 = h2.defineDone();
            call missing(issueid, name);
        end;

        set &indata;
            by issueid;
        length __vname __vvalue $32 ;
        call missing(__vname,__vvalue);
        rc = h1.find();

        * if not found in hash table h1 -- issueid was not generated as an sas dataset;
        if rc > 0 then return;

        * begin to look up in hash table h2 -- if key/report variable is valid;
        array kr{*} key: rep:;
        length __name $200;
        do i = 1 to dim(kr);
            * Ken on 2013/03/06: * means a variable only used for key variables for compare;
            kr[i] = upcase(scan(kr[i], 1, '()*'));
            * exit current iteration if kr[i] is null ;
            if kr[i] = ' ' then continue;
            * name is actual variable name (value of key[i]/rep[i]);
            name = kr[i];
            * look up in the hash table;
            rc = h2.find();
            * if name is found, then good to go (exit current iteration);
            if rc = 0 then continue;
            * if name is not found then flag it as an e r r o r; 
            call symput('IsErr', '1');
            * __name is array variable name (rep1 - rep? key1 - key?);
            __name = upcase(vname(kr[i]));
            * convert __name to excel column name;
            if index(__name, 'REP') then __name = 'REPORT VARIABLE '||substr(__name,4);
            else if index(__name, 'KEY') then __name = 'KEY VARIABLE '||substr(__name,4);
            * put an e r r o r statement in SAS log;
            put "ERR" "OR: Variable " name " in column " __name ", line " linenum1 " is not found in datasets " issueid;
        end;
    run;


%mend chkVars;
