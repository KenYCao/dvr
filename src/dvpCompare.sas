/*
    Program Name: dvp_comp.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/12/12

    Compare all new and backup issue datasets

    REVISION HISTORY:
    2014/03/18 Ken Cao: macro %dvpIssueDsetCompare --> change parameter reportvars to comparevars.
                        macro %dvpIssueDsetCompare --> parameter comparevars --> all variables in key variables and compare variables. 
        
*/

%macro dvpCompare(pdata =, pdatabk =);
    
    %local allIssueList;
    %local nIssue;
    %local issueDset;
    %local i;

    %local _exist;  /*return code from %IsDsetExist*/
    %local nobs; /*return code from %getDsetInfo*/

    %local keyVars4Comp;
    %local keyvars;
    %local reportVars;
    %local vars2compare;

    /*initialization*/
    %let _exist = 0;
    %let nobs   = 0;

    %getIssueList(&dvpConfigDset(where=(nobs>0)));    

    %do i = 1 %to &nIssue;

        %let issueDset = %scan(&allIssueList, &i, " ");

        %IsSASDsetExist(&pdatabk..&issueDset);
        %if &_exist = 1 %then
            %do;
                %getDsetInfo(indata = &pdatabk..&issueDset, getNOBS = Y);
            %end;

        /*If issue dataset not in backup directory or # of observations is 0 */
        %if &_exist = 0 or &nobs = 0 %then
            %do;
                data &pdatalibrf..&issueDset;
                    modify &pdatalibrf..&issueDset;
                    _type_  = 'N';
                    _diff_  = ' ';
                    _diff2_ = ' ';
                run;
            %end;
        %else
            %do;
                /*
                %getKeyVars4Compare(&issueDset);
                %getReportVars(&issueDset);
                %getKeyVars(&issueDset);
                */

                %getVars2Compare(&issueDset);    
                
                %dvpIssueDsetCompare
                (
                    issueID    = &issueDset,
                    comparevars = %str(&vars2compare)
                );
            %end;
    %end; 


    
%mend dvpCompare;


