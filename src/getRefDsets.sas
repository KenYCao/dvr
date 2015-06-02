/*
    Program Name: getRefDsets.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/21

    return reference datasets
*/

%macro getRefDsets(issueID);

    %let refDsets = %str();

    data _null_;
        set &dvpRefConfigDset;
        where issueid = "&issueID";
        call symput('refDsets', strip(refDsets));
    run;

%mend getRefDsets;
