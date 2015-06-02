/*
    Program Name: updatePDATA.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Intial Date: 2014/03/11

    REVISION HISTORY:
    
    2014/03/26 Ken Cao: For modified issue, get record ID and Q2 COMMENT when previous Q2 COMMENT is available
    2014/03/27 Ken Cao: For modified issue, if it was previously marked as deleted, then a message will be printed under Q2 comment.
    2014/07/04 Ken Cao: Add issue/findings (issue description speific to record).
    
*/

%macro updatePDATA(updateFile);

    %local refreshPdata;
    %local _exist;
    %local updateMaster;
    %local nIssue;
    %local ALLissueList;
    %local i;
    %local issueDset;

    %let refreshPdata = N;

    %if %length(&updateFile) > 0 %then %do;
        * import update file;
        * output: &updateTBL;
        %importUpdateTBL(&pgmdir/&updateFile);

        %if IsErr = 1 %then %return;
    
        /*
        %IsSASDsetExist(&debuglibrf..&updateTBL);
        %let _existTmp = &_exist;
        */
        
        %if &reGenerateData = Y %then %let updateMaster = &updateTBL;
        %else %do;
            %IsSASDsetExist(&pdatalibrf..&MD5TBL);
            %if _exist = 0 %then %let updateMaster = &updateTBL;
            %else %do;
                proc sort data = &updateTBL; by _all_; run;
                proc sort data = &pdatalibrf..&MD5TBL; by _all_; run;

                data __update2;
                    merge &updateTBL(in = a) &pdatalibrf..&MD5TBL(in = b);
                        by _all_;
                    if a and not b;
                run;

                %let updateMaster = __update2;
            %end;
        %end;
        %let refreshPdata = Y;
    %end;   


    %if &refreshPdata = N %then %return;

    proc sort data = &updateMaster out = _update0;
        by issueid;
    run;


    proc sort data = _update0;
        by issueid subject __groupid __recid;
    run;

    data _update1;
        set _update0;
            by issueid subject __groupid;
        where __groupid > ' ';
        length __q2cmnt2 __clientcmnt2 __querystat2 $1024;
        retain __q2cmnt2 __clientcmnt2 __querystat2;
        if first.__groupid then do;
            __q2cmnt2     = __q2cmnt;
            __clientcmnt2 = __clientcmnt;
            __querystat2  = __querystat;
        end;
        else do;
            __q2cmnt2     = coalescec(__q2cmnt, __q2cmnt2);
            __clientcmnt2 = coalescec(__clientcmnt, __clientcmnt2);
            __querystat2  = coalescec(__querystat, __querystat2);
        end;
        if last.__groupid;
        keep issueid subject __groupid __q2cmnt2 __clientcmnt2 __querystat2;
    run;

    data _update2;
        merge _update0 _update1;
            by issueid subject __groupid;
        __q2cmnt     = coalescec(__q2cmnt, __q2cmnt2);
        __clientcmnt = coalescec(__clientcmnt, __clientcmnt2);
        __querystat  = coalescec(__querystat, __querystat2);
        drop __q2cmnt2 __clientcmnt2 __querystat2;
    run;


    data trans; /* transancation dataset */
        set _update2;
        rename __deleted    = __deleted2;
        rename __groupid    = __groupid2;
        rename __initdt     = __initdt2;
        rename __finding    = __finding_2;
        
        rename __q2cmnt     = __q2cmnt2;
        rename __clientcmnt = __clientcmnt2;
        rename __querystat  = __querystat2;

        length __recid2 $64;
        __recid2 = __recid; 
    run;



/*    %getIssueList(&dvpConfigDset(where=(__IsDataExist='Y')));*/
    %getIssueList(trans);   

    %do i = 1 %to &nIssue;

        %let issueDset = %scan(&ALLissueList, &i, " ");
        %IsSASDsetExist(&pdatalibrf..&issueDset);

        %if &_exist = 1 %then %do;
            data &pdatalibrf..&issueDset;
                set trans;
                do until (_iorc_ = %sysrc(_dsenom));
                    * update deletion flag and Q2 comment;
                    modify &pdatalibrf..&issueDset key = __recid;
                    select (_iorc_);
                        when (%sysrc(_sok)) do; 
                            __deleted    = __deleted2; 
                            __groupid    = __groupid2;
                            __initdt     = __initdt2;

                            * Ken on 2014/07/04: only replace with non-blank values;
                            __finding2   = __finding;
                            __finding    = coalescec(__finding_2, __finding);


                            __q2cmnt     = __q2cmnt2;
                            __clientcmnt = __clientcmnt2;
                            __querystat  = __querystat2;
                            
                            replace &pdatalibrf..&issueDset;
                        end;
                        when (%sysrc(_dsenom)) do;
                            _error_ = 0; 
                        end; 
                        otherwise;
                    end;
                end;
             run;

             * for modified issue;
             data &pdatalibrf..&issueDset;
                set trans;
                do until (_iorc_ = %sysrc(_dsenom));
                    modify &pdatalibrf..&issueDset key = __keyid;
                    select (_iorc_);
                        when (%sysrc(_sok)) do; 
                            if __recid2 ^= __recid and __q2cmnt2 > ' ' then do;
                                __q2cmnt = 'Previous record ID is '||strip(__recid2)||".&odsescapechar.n"
                                            ||'Previous comment: <'||strip(__q2cmnt2)||'>'||"&odsescapechar.n";
                                replace &pdatalibrf..&issueDset;
                            end;
                            else if __recid2 ^= __recid and __deleted2 = 'Y' then do;
                                __q2cmnt =  'This record was deleted last time and was modified in this run' ||
                                            'Previous record ID is '||strip(__recid2)||".&odsescapechar.n" || __q2cmnt2;
                                replace &pdatalibrf..&issueDset;
                            end;
                        end;
                        when (%sysrc(_dsenom)) do;
                            _error_ = 0; 
                        end; 
                        otherwise;
                    end;
                end;
             run;
         %end;

    %end;
%mend updatePDATA;
