/*
    Program Name: alterPDATA.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/11


   Revision History:
   Ken Cao on 2014/07/01: Add a new varaible __GROUPID to group records together (for layout 3 reports).
   Ken Cao on 2015/02/15: Add new variables (_diff3_, _mdfnum_)
*/


%macro alterPDATA();

    %local nIssue;
    %local ALLissueList;
    %local i;
    %local issueDset;
    
    proc sql;
        create table _ALLissueID as
        select upcase(memname) as issueid length = 32
        from dictionary.tables
        where libname = "%upcase(&pdatalibrf)"
    ;
    quit;

    %getIssueList(_ALLissueID);

    %do i = 1 %to &nIssue;
        %let issueDset = %scan(&ALLissueList, &i, " ");

        proc sql;
            alter table &pdatalibrf..&issueDset
            add 
                __recid      char  length = 64,
                __keyid      char  length = 64,
                __groupid    char  length = 255,
                __finding    char  length = 1024,
                __finding2   char  length = 1024,
                __q2cmnt     char  length = 1024,
                __clientcmnt char  length = 1024,
                __querystat  char  length = 1024,
                __initdt     char  length = 40,
                __deleted    char  length = 1,
                _type_       char  length = 1,
                _diff_       char  length = 32767,
                _diff2_      char  length = 32767,
                _diff3_      char  length = 32767,
                _mdfnum_     num   length = 8
            ;

        quit;
    %end;


%mend alterPDATA;
