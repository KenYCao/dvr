/*
    Program Name: updateNOBS.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/10
*/


%macro updateNOBS(indata);

    %local nIssue;
    %local ALLissueList;
    %local i;
    %local issueDset;
    %local _exist;

    
    %getIssueList(&indata);


    %do i = 1 %to &nIssue;

        %let issueDset = %upcase(%scan(&ALLissueList, &i, " "));

        %IsSASDsetExist(&pdatalibrf..&issueDset);

        %if &_exist = 1 %then %do;
            proc sql;
                update &indata
                set nobs = (
                select count(ifn(__deleted = ' ', 1, .))
                from &pdatalibrf..&issueDset
                )
                where issueid = "&issueDset";
                ;
            quit;
        %end;
    %end;

%mend updateNOBS;
