/*
    Program Name: getRefRangeName.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/21

    Get reference range name for specified subject/issueid
*/

%macro getRefRangeName(issueid, subject);
    
    %let refRangeName = %str();

    data _null_;
        set &subjectIssueSummaryDset;
        where issueid = "&issueID"
        and subject = "&subject";
        call symput('refRangeName', strip(refDsetRangeName));
    run;

%mend getRefRangeName;
