/*
    Program Name: exportRecordID.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/10

    Export all record ID with __DELTED/__Q2CMENT.
*/


%macro exportRecordID();
    
    %local nIssue;
    %local ALLissueList;
    %local i;
    %local issueDset;
    
    %getIssueList(&dvpConfigDset(where=(__IsDataExist='Y')));


    data &MD5TBL;
        length 
            issueid $32 
            subject $255 
            __groupid $255 
            __recid $64 
            __keyid $64  
            __finding $1024  
            __q2cmnt $1024 
            __clientcmnt $1024 
            __initdt $40 
            __querystat $1024 
            __deleted $1
        ;
        label 
             issueid      = 'Dataset Name'
             subject      = "Subject ID"
             __recid      = 'Record ID'
             __keyid      = 'ID for Key Variable(s)'
             __finding    = 'Issue Finding'
             __q2cmnt     = 'Q2 Comment'
             __clientcmnt = 'Client Comment'
             __initdt     = 'Initial Report Date'
             __deleted    = 'Deleted'
             __groupid    = 'Group ID'
         ;
         if 0;
         call missing(issueid, subject, __groupid, __recid, __keyid,__finding, __q2cmnt,  __clientcmnt, __initdt, __querystat, __deleted);
    run;

    %do i = 1 %to &nIssue;
        
        %let issueDset = %scan(&ALLissueList, &i, " ");

        proc sql;
            insert into &MD5TBL(
                issueid, 
                subject, 
                __groupid, 
                __recid, 
                __keyid,    
                __finding, 
                __q2cmnt, 
                __clientcmnt, 
                __initdt,
                __querystat,
                __deleted
                )
            select 
                "&issueDset",
                &subjectvar,
                __groupid,
                __recID,
                __keyID,
                case
                    when __finding = __finding2 then ' '
                    else __finding end,
                __q2cmnt,
                __clientcmnt,
                __initdt,
                __querystat,
                __deleted
            from &pdatalibrf..&issueDset
            ;
        quit;

    %end;

    /*
    proc sql;
        update &MD5TBL
        set __q2cmnt = '"'||strip(translate(__q2cmnt, '0A'x, '0D'x))
        where (index(__q2cmnt, '0A'x) or index(__q2cmnt, '0D'x)) 
        and substr(__q2cmnt, 1, 1) ^ = '"';
    quit;

    * export MD5 table to directory &outputdir;
    proc export data = &MD5TBL 
    outfile = "&outputdir/ALL_RECORD_ID.csv"
    dbms = csv
    label
    replace;
    run;
    */

    %export2CSV(indata=&MD5TBL, outfile=&outputdir/ALL_RECORD_ID.csv);

    * stores MD5 table in library &pdatalibrf;
    data pdata.&MD5TBL;
        set &MD5TBL;
    run;



%mend exportRecordID;
