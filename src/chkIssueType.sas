/*
    Program Name: chkIssueType.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/25

    Check issue type
*/

%macro chkIssueType(indata);

    data _ALLissueType;
        length issueType $255;
        i = 1;
        do while (scan("&ALLissueType", i, "@") > ' ');
            issueType = strip(upcase(scan("&ALLissueType", i, "@")));
            i = i + 1;
            output;
        end;
        keep issueType;
    run;

    data _null_;
        length issueType $255;
        if _n_ = 1 then do;
            declare hash h (dataset:'_ALLissueType');
            rc = h.defineKey('issueType');
            rc = h.defineDone();
            call missing(issueType);
        end;
        set &indata;
        issueType = strip(upcase(issuetyp));
        rc = h.find();
        if rc > 0 then do;
            call symput('IsErr', '1');
            put "ERR" "OR: In" "valid issue type: " issueType " of issue ID: " issueid " in configuraion file.";
        end;
    run;
    

%mend chkIssueType;
