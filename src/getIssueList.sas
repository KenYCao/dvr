/*
    Program Name: getIssueList.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/12/12
*/


/**************************************************************************************************************
REVISION HISTORY:

2014/03/10 Ken Cao: Add a parameter exclueNULLissue to control whether issues without a record to be counted.
2014/03/11 Ken Cao: Redesign the macro. Only one input parameter (a SAS dataset that contains variable ISSUEID).

***************************************************************************************************************/


%macro getIssueList(indata);

    %local blank;

    %let blank = ;
    
    %let allIssueList =;
    %let nIssue   = 0;


    proc sort data = &indata nodupkey out = _ALLissueID; 
        by issueid;
    run;

    proc sql noprint;
        select distinct upcase(issueid) 
        into: allIssueList
        separated by " "
        from _ALLissueID
        ;
    quit;

    %if %length(&allIssueList) > 0 %then
        %do;
            %let nIssue = %sysfunc(countc(&allIssueList, " "));
            %let nIssue = %eval(&nIssue+ 1);
        %end;

%mend getIssueList;
