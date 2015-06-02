/*
    Program Name; chkSubjectVar.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/02/26
*/


%macro chkSubjectVar(subjectvar);
    
    %local allIssueList;
    %local nIssue;
    %local i;
    %local varnum;
    %local blank;
    %local issueDset;

    %let blank =;

    %getIssueList(&dvpConfigDset(where=(nobs>0)));

    %do i = 1 %to &nIssue;
        %let issueDset = %scan(&allIssueList, &i, " ");
        
        %getVarInfo
        (
            indata    = pdata.&issueDset,
            invar     = &subjectvar,
            getvarnum = Y
        );

        %if &varnum = 0 %then
            %do;
                %let IsErr = 1;
                %put ERR&blank.OR: Variable &subjectvar not found in dataset &issueDset;
            %end;
        
    %end;
    
%mend chkSubjectVar;
