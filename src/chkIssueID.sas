/*
    Program Name: chkIssueID
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/25

    Check if all genrated issue was configured
*/

%macro chkIssueID(indata);

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

    * Check if configuration file including all issue datasets;
    data _null_;
        merge _allIssDset0(in=a) &indata(in = b);
            by issueid;
        if not b and first.issueid then do;
            call symput('IsErr', '0.5');  
            put "WARN" "ING: Issue dataset " issueid "was not configured in configuration file and will be ignored in DVR report";
        end;
    run;
    

%mend chkIssueID;
