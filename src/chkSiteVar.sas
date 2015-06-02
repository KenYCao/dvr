/*
    Program Name; chkSiteVar.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/02/26
*/


%macro chkSiteVar(sitevar);
    
    %local useFormula;
    %local formula;
    %local allIssueList;
    %local nIssue;
    %local i;
    %local issueDset;
    %local varnum;
    %local blank;

    %let useFormula = N;

    %getIssueList(&dvpConfigDset(where=(nobs>0)));

    %if "%substr(&sitevar, 1, 1)" =  "=" %then 
        %do;
            %let useFormula = Y;
            %let formula    = &sitevar;
            %let sitevar    = site;
        %end;

    %if &useFormula = N %then 
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
    %else
        %do i = 1 %to &nIssue;
            %let issueDset = %scan(&allIssueList, &i, " ");
            data pdata.&issueDset;
                set pdata.&issueDset;
                length site $256;
                site = &formula;
            run;
            %if &syserr > 0 %then 
                %do;
                    %let IsErr =  1;
                    %return;
                %end;
        %end;
    
%mend chkSiteVar;
