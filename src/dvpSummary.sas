/*
    Program Name: dvpSummary.sas
        @Author: Ken Cao(yong.cao@q2bi.com)
        @Initial Date: 2014/03/05
*/


/****************************************************************************************************
REVISION HISTORY

2014/03/10 Ken Cao: For issue summary dataset, keep all issues (rather than only NOBS>0).
2014/03/27 Ken Cao: Display # of repeat issues.

****************************************************************************************************/

%macro dvpSummary(byIssue=, bySourceDset=, bySite=, bySubject=);

    %local nIssue;
    %local AllIssueList;
    %local i;
    %local issueDset;
    %local dsid;
    %local rc;
    %local nIssueType;

    * get all issue datasets with at least one record;
    %getIssueList(&dvpConfigDset(where=(nobs>0)));

    * collector for all issue records (deleted = ' '); 
    data _presum0;
        length subject site $255 issueid $32 _type_ $1 __querystat $255;;
        call missing(subject, site, issueid, _type_, __querystat);
        if 0;
    run;

    * collector for all deleted issue records;
    data _preDeleted0;
        length site $255 subject $255 issueid $32 _type_ $1 __querystat $255;
        call missing(site, subject, issueid, _type_, __querystat);
        if 0;
    run;


    * gathering all issue record;
    %do i = 1 %to &nIssue;
        %let issueDset = %upcase(%scan(&AllIssueList, &i, " "));
        %let dsid      = %sysfunc(open(&pdatalibrf..&issueDset));
        %let rc        = %sysfunc(close(&dsid));

        proc sql;
            insert into _presum0 (subject, site, issueid, _type_, __querystat)
            select 
                %if &bySubject = Y %then
                &subjectvar;
                %else
                ' ';
                %if %length(&sitevar) > 0 %then
                , &sitevar;
                %else
                , ' ';
                , "&issueDset"
                %if &compare = Y %then
                ,  _type_;
                %else
                , ' ';
                ,coalescec(scan(__querystat, 1, ':'), ' BLANK')
            from &pdatalibrf..&issueDset
            where __deleted = ' '
            %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
            and findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
            %if &bySubject = Y and %length(&subjects) > 0 %then 
            and findw(strip("&subjects"), strip(upcase(&subjectVar)), '@') > 0;
            ;   

            insert into _preDeleted0(site, subject, issueid, _type_, __querystat)
            select 
                %if %length(&sitevar) > 0 %then
                &sitevar;
                %else
                ' ';
                %if &bySubject = Y %then
                , &subjectvar;
                %else
                ,' ';
                , "&issueDset"
                , _type_
                ,coalescec(scan(__querystat, 1, ':'), ' BLANK')
            from &pdatalibrf..&issueDset
            where __deleted = 'Y'
            %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
            and findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
            %if &bySubject = Y and %length(&subjects) > 0 %then 
            and findw(strip("&subjects"), strip(upcase(&subjectVar)), '@') > 0;
            ;
        quit;

    %end;

    * get issue info from configuration file. ;
    data _presum1;
        length message $1024 sdset $200 sdsetlbl $1024 issuetypn 8 issuetyp $40 issueid $32 nvar 8;
        if _n_ = 1 then
            do;
                declare hash cfg (dataset:"&dvpConfigDset");
                rc = cfg.defineKey('issueid');
                rc = cfg.defineData('message', 'issuetyp', 'issuetypn', 'sdset', 'sdsetlbl', 'nvar');
                rc = cfg.defineDone();
                call missing(issueid, message, issuetyp, issuetypn, sdset, sdsetlbl, nvar);
            end;
        set _presum0;

        rc = cfg.find();

        if _type_ > ' ' then output;
        _type_ = 'T'; output;
    run;

    data _presum;
        set _presum1;
        if site > ' ' then output;
        site = "&allsiteTXT"; output;
    run;

    data _preDeleted1;
        set _preDeleted0;
        if _type_ > ' ' then output;
        _type_ = 'T'; output;
    run;

    data _preDeleted;
        set _preDeleted1;
        if site > ' ' then output;
        site = "&allsiteTXT"; output;
    run;


    data _mkIssTyp0;
        set &dvpALLissueTypeDset;
        call symput('nIssueType', strip(put(_n_, best.)));
        length count $40;
        call missing(count);
        keep issueTyp issueTypn count;
    run;

    /*
    data _mkIssTyp0;
        length issueTyp $255  issueTypn 8 allIssueType $32767 count $40;
        allIssueType = "&allIssueType";
        count = ' ';
        i = 1;
        do while (scan(allIssueType, i, '@') > ' ');
            issueTyp  = upcase(scan(allIssueType, i, '@'));
            issueTypn = i;
            i         = i + 1;
            output;
        end;
        keep issueTyp issueTypn count;
    run;

    proc sort data=_presum1 nodupkey out=_chkIssTyp(keep=issueTyp);
        by issueTyp;
    run;

    proc sort data = _mkIssTyp0; by issueTyp; run;

    data _mkIssTyp1;
        merge _chkIssTyp(in=b ) _mkIssTyp0(in=a rename=(issueTypn=in_issueTypn)) ;
            by issueTyp;
        if not a then put 'WARN' 'ING: You may miss to put issue type: ' issueTyp ' in setup';
        if not b then put 'WARN' 'ING: Please be aware that no issue generated with type ' issuetyp;
        issueTypn = coalesce(in_issueTypn, 999);
        drop in_issueTypn;
    run;

    proc sort data = _mkIssTyp1; by issueTypn issueTyp; run;

    data _mkIssTyp2;
        set _mkIssTyp1;
        retain issueTypn2;
        if issueTypn < 999 then issueTypn2 = issueTypn;
        else issueTypn2 = issueTypn2 + 1;
        issueTypn = issueTypn2;
    run;

    data _null_;
        set _mkIssTyp2 end=_eof_;
        length _ALLissueTyp $32767;
        retain _ALLissueTyp;
        if _n_ = 1 then _ALLissueTyp = issueTyp;
        else _ALLissueTyp = _ALLissueTyp||'@'||issueTyp;
        if _eof_ then call symput('allIssueType', strip(_ALLissueTyp));
    run;

    */

    proc transpose data = _mkIssTyp0 out = _mkIssTyp3(drop = _:) prefix = CNT_;
        id issueTypn;
        idlabel issuetyp;
        var count;
    run;

    data _mkIssTyp;
        set _mkIssTyp3;
        where 0;
    run;


    ********************************************************************************************************************;
    * deleted issues;
    ********************************************************************************************************************;
    proc sql;
        create table &deletedIssueDset as
        select distinct
            site, 
            subject,
            issueid, 
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _preDeleted
        group by issueid, site;
    quit;


    ********************************************************************************************************************;
    * summarize by source dataset ;
    ********************************************************************************************************************;

    /*
    %let nIssueType = %sysfunc(countc(&allIssueType, @));
    %let nIssueType = %eval(&nIssueType + 1);
    %do i = 1 %to &nIssueType;
        %local issueType&i;
        %let issueType&i = %upcase(%scan(&allIssueType, &i, @));
    %end;
    */



    data _preSdsetSummary;
        set _presum;
        /*
        output;
        sdset    = "&allDsetTXT";
        sdsetlbl = ' ';
        output;
        */
    run;

    proc sql;
        create table _dvpSdsetSummary0 as
        select distinct
            site,
            sdset,
            sdsetlbl,
            issuetypn,
            issuetyp,
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _preSdsetSummary
        group by site, sdset, sdsetlbl, issuetypn
        ;
    quit;

    data _dvpSdsetSummary1;
        set _dvpSdsetSummary0;
        length count $40;
        %if &compare = N %then
        count = strip(put(nobs, best.));
        %else
        count = strip(put(nobs, best.)) || '/' ||strip(put(nobsnew, best.)) || '/' || strip(put(nobsmdf, best.)) || '/'
                || strip(put(nobsrpt, best.));
        ;
        keep site sdset sdsetlbl issuetyp issuetypn count;
    run;

    proc sort data = _dvpSdsetSummary1; by site sdset sdsetlbl issuetypn; run;

    proc transpose data = _dvpSdsetSummary1 out = _dvpSdsetSummary2(drop = _:) prefix = CNT_;
        by site sdset sdsetlbl;
        id issuetypn;
        idlabel issuetyp;
        var count;
    run;

    data _dvpSdsetSummary3;
        set _mkIssTyp _dvpSdsetSummary2 ;
        array cnt{*} CNT_:;

        length nobs nobsnew nobsmdf nobsrpt 8;

        nobs    = 0;
        nobsnew = 0;
        nobsmdf = 0;
        nobsrpt = 0;

        %if &compare = N %then %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1  %end;
        ;
        %end;
        %else %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1 %end;;
        array cntn2{*} %do i = 1 %to &nIssueType; CNT_&i._2 %end;;
        array cntn3{*} %do i = 1 %to &nIssueType; CNT_&i._3 %end;;
        array cntn4{*} %do i = 1 %to &nIssueType; CNT_&i._4 %end;;
        %end;
        ;
        do i = 1 to dim(cnt);
            %if &compare = N %then %do;
            cnt[i]   = coalescec(cnt[i], '0');
            cntn1[i] = input(cnt[i], best.);
            nobs     = nobs + cntn1[i];
            %end;
            %else %do;
            cnt[i]    = coalescec(cnt[i], '0/0/0/0');
            cntn1[i]  = input(scan(cnt[i], 1, '/'), best.);
            cntn2[i]  = input(scan(cnt[i], 2, '/'), best.);
            cntn3[i]  = input(scan(cnt[i], 3, '/'), best.);
            cntn4[i]  = input(scan(cnt[i], 4, '/'), best.);
            nobs      = nobs + cntn1[i];
            nobsnew   = nobsnew + cntn2[i];
            nobsmdf   = nobsmdf + cntn3[i];
            nobsrpt   = nobsrpt + cntn4[i];
            %end;
            ;
        end;
        drop i;
        %do i = 1 %to &nIssueType; drop CNT_&i;  %end;
    run;

    proc sort data = _dvpSdsetSummary3 out = &dsetSummaryDset;
        by site sdset;
        where
        /*
        %if &bysite = Y %then
        site ^= "&allSiteTXT";
        */
        %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
        findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
        %else 
        site = "&allSiteTXT";
        ;
    run;



    ********************************************************************************************************************;
    * summarize by issues ;
    ********************************************************************************************************************;
    

    data _preIssueSummary;
        set _presum;
        /*
        output;
        issueid   = "&allIssueTXT"; 
        issuetypn = 0;
        issuetyp  = ' ';
        message   = ' ';
        output;
        */
    run;

    proc sql;
        create table _dvpIssueSummary0 as
        select distinct
            site,
            sdset,
            issueid,
            issuetypn,
            issuetyp,
            message,
            nvar,
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _preIssueSummary
        group by site, sdset, issueid
        ;
    quit;


    * generate a list of all sites;
    proc sort data = _dvpIssueSummary0 out =_ALLsite(keep = site) nodupkey; 
        by site;
    run;

    * generate a list of all isssues from configuration file;
    proc sort data = &dvpConfigDset out = _ALLissue(keep = issueid sdset issuetypn issuetyp message nvar);
        by issueid; 
    run;

    * generate a combination of all sites and all issues;
    proc sql;
        create table _ALLSiteIssue as
        select distinct
            site,
            issueid,
            sdset,
            issuetypn,
            issuetyp,
            message,
            nvar
        from _ALLsite, _ALLissue;
    quit;


    proc sort data = _dvpIssueSummary0; by site sdset issueid; run;
    proc sort data = _ALLSiteIssue; by site sdset issueid; run;

    data _dvpIssueSummary1;
        merge _ALLSiteIssue _dvpIssueSummary0(in = b);
            by site sdset issueid;
        if not b then
            do;
                nobs    = 0;
                nobsnew = 0;
                nobsmdf = 0;
                nobsrpt = 0;
            end;
    run;

    data &issueSummaryDset; 
        set _dvpIssueSummary1;
        %if &compare = N %then
        drop nobsnew nobsmdf nobsrpt;;
        where
        /*
        %if &bysite = Y %then
        site ^= "&allSiteTXT";
        */
        %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
        findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
        %else 
        site = "&allSiteTXT";
        ;
    run;



    ********************************************************************************************************************;
    * summarize by subject ;
    ********************************************************************************************************************;
    %if &bySubject = N %then %return;

    data _preIssueSummary;
        set _presum;
        /*
        output;
        subject = "&allSubjectTXT";
        output;
        */
    run;

    proc sql;
        create table _dvpSubjectSummary0 as
        select distinct
            site,
            subject,
            issuetypn,
            issuetyp,
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _presum
        group by site, subject, issuetypn
        ;
    quit;

    data _dvpSubjectSummary1;
        set _dvpSubjectSummary0;
        length count $40;
        %if &compare = N %then
        count = strip(put(nobs, best.));
        %else
        count = strip(put(nobs, best.)) || '/' ||strip(put(nobsnew, best.)) || '/' || strip(put(nobsmdf, best.)) || '/'
                ||strip(put(nobsrpt, best.));
        ;
        keep site subject issuetypn issuetyp count;
    run;

    proc sort data = _dvpSubjectSummary1; by site subject issuetypn; run;
    
    proc transpose data = _dvpSubjectSummary1 out = _dvpSubjectSummary2(drop = _:) prefix = CNT_;
        by site subject;
        id issuetypn; 
        idlabel issuetyp;
        var count;
    run;

    data _dvpSubjectSummary3;
        set _mkIssTyp _dvpSubjectSummary2;

        length nobs nobsnew nobsmdf nobsrpt 8;

        nobs    = 0;
        nobsnew = 0;
        nobsmdf = 0;
        nobsrpt = 0;


        array cnt{*} CNT_:;

        %if &compare = N %then %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1  %end;
        ;
        %end;
        %else %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1 %end;;
        array cntn2{*} %do i = 1 %to &nIssueType; CNT_&i._2 %end;;
        array cntn3{*} %do i = 1 %to &nIssueType; CNT_&i._3 %end;;
        array cntn4{*} %do i = 1 %to &nIssueType; CNT_&i._4 %end;;
        %end;
        ;
        do i = 1 to dim(cnt);
            %if &compare = N %then %do;
            cnt[i]   = coalescec(cnt[i], '0');
            cntn1[i] = input(cnt[i], best.);
            nobs     = nobs + cntn1[i];
            %end;
            %else %do;
            cnt[i]    = coalescec(cnt[i], '0/0/0/0');
            cntn1[i]  = input(scan(cnt[i], 1, '/'), best.);
            cntn2[i]  = input(scan(cnt[i], 2, '/'), best.);
            cntn3[i]  = input(scan(cnt[i], 3, '/'), best.);
            cntn4[i]  = input(scan(cnt[i], 4, '/'), best.);
            nobs      = nobs + cntn1[i];
            nobsnew   = nobsnew + cntn2[i];
            nobsmdf   = nobsmdf + cntn3[i];
            nobsrpt   = nobsrpt + cntn4[i];
            %end;
            ;
        end;
        drop i;
        %do i = 1 %to &nIssueType; drop CNT_&i;  %end;

    run;

    proc sort data = _dvpSubjectSummary3 out = &subjectSummaryDset; 
        by site subject;
        where
        /*
        %if &bysite = Y %then
        site ^= "&allSiteTXT";
        */
        %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
        findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
        %else 
        site = "&allSiteTXT";
        ;
    run;


    ********************************************************************************************************************;
    * summarize by subject and issue ;
    ********************************************************************************************************************;
    %if &bySubject = Y %then %do;
    proc sql;
        create table _dvpSubjectIssueSummaryDset0 as
        select distinct
            site,
            subject,
            issuetypn,
            issuetyp,
            a.issueid,
            refdsets,
            coalesce(b.nrefdset, 0) as nrefdset,
            case 
                when nrefdset > 0 then '_'||put(md5(strip(subject)||'@'||strip(a.issueID)||'@'||strip(refdsets)), $hex32.)
                else ' ' end as RefDsetrangeName length=33,
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _presum as a
        left join (select distinct issueid, refdsets, nrefdset from &dvpRefConfigDset) as b
        on a.issueid = b.issueid
        group by site, subject, a.issueid
        order by a.issueid;
    quit;

    proc sort data = _dvpSubjectIssueSummaryDset0 out = &subjectIssueSummaryDset;
        by site subject issuetypn;
        where
        /*
        %if &bysite = Y %then
        site ^= "&allSiteTXT";
        */
        %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
        findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
        %else 
        site = "&allSiteTXT";
        ;
    run;
    %end;



    ********************************************************************************************************************;
    * summarize query status ;
    ********************************************************************************************************************;
    proc sql;
        create table _dvpQstatSummary0 as
        select distinct
            site,
            subject,
            __querystat,
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _presum
        group by site, subject, __querystat
        ;
    quit;

    * assign numeric code to each query status;
    proc sort data = _dvpQstatSummary0 out = _ALLQstat0(keep=__querystat) nodupkey; 
        by __querystat;
    run;

    data _ALLQstat;
        set _ALLQstat0;
        __querystatn + 1;
    run;

    data _dvpQstatSummary1;
        length __querystat $255 __querystatn 8;
        if _n_ = 1 then do;
            declare hash h (dataset:'_ALLQstat');
            rc = h.defineKey('__querystat');
            rc = h.defineData('__querystatn');
            rc = h.defineDone();
            call missing(__querystat, __querystatn);
        end;
        set _dvpQstatSummary0;
        rc = h.find();
        drop rc;
    run;

    data _dvpQstatSummary2;
        set _dvpQstatSummary1;
        length count $40;
        %if &compare = N %then
        count = strip(put(nobs, best.));
        %else
        count = strip(put(nobs, best.)) || '/' ||strip(put(nobsnew, best.)) || '/' || strip(put(nobsmdf, best.)) || '/'
                ||strip(put(nobsrpt, best.));
        ;
        keep site subject __querystat __querystatn count;
    run;

    proc sort data = _dvpQstatSummary2; by site subject __querystatn; run;
    
    proc transpose data = _dvpQstatSummary2 out = _dvpQstatSummary3(drop = _:) prefix = CNT__;
        by site subject;
        id __querystatn; 
        idlabel __querystat;
        var count;
    run;

    data _dvpQstatSummary4;
        set _dvpQstatSummary3;
        array cnt{*} CNT__:;
        do i = 1 to dim(cnt);
            cnt[i] = coalescec(cnt[i], '0/0/0/0');
            cnt[i] = scan(cnt[i], 1, '/');
        end;
        drop i;
    run;

    /*
    data _dvpQstatSummary4;
        set _dvpQstatSummary3;

        length nobs nobsnew nobsmdf nobsrpt 8;

        nobs    = 0;
        nobsnew = 0;
        nobsmdf = 0;
        nobsrpt = 0;


        array cnt{*} CNT__:;

        %if &compare = N %then %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1  %end;
        ;
        %end;
        %else %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1 %end;;
        array cntn2{*} %do i = 1 %to &nIssueType; CNT_&i._2 %end;;
        array cntn3{*} %do i = 1 %to &nIssueType; CNT_&i._3 %end;;
        array cntn4{*} %do i = 1 %to &nIssueType; CNT_&i._4 %end;;
        %end;
        ;
        do i = 1 to dim(cnt);
            %if &compare = N %then %do;
            cnt[i]   = coalescec(cnt[i], '0');
            cntn1[i] = input(cnt[i], best.);
            nobs     = nobs + cntn1[i];
            %end;
            %else %do;
            cnt[i]    = coalescec(cnt[i], '0/0/0/0');
            cntn1[i]  = input(scan(cnt[i], 1, '/'), best.);
            cntn2[i]  = input(scan(cnt[i], 2, '/'), best.);
            cntn3[i]  = input(scan(cnt[i], 3, '/'), best.);
            cntn4[i]  = input(scan(cnt[i], 4, '/'), best.);
            nobs      = nobs + cntn1[i];
            nobsnew   = nobsnew + cntn2[i];
            nobsmdf   = nobsmdf + cntn3[i];
            nobsrpt   = nobsrpt + cntn4[i];
            %end;
            ;
        end;
        drop i CNT__:;
    run;
    */


    proc sort data = _dvpQstatSummary4 out = &QstatSummaryDset; 
        by site subject;
        where
        /*
        %if &bysite = Y %then
        site ^= "&allSiteTXT";
        */
        %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
        findw(strip("&sites"), strip(upcase(&sitevar)), '@') > 0;
        %else 
        site = "&allSiteTXT";
        ;
    run;








    ********************************************************************************************************************;
    * summarize by site ;
    ********************************************************************************************************************;
    %if &bySite = Y %then %do;
/*    %if %length(&sitevar) = 0 %then %return;*/

    proc sql;
        create table _dvpSiteSummary0 as
        select distinct
            site,
            count(distinct subject) as nsubject,
            issuetypn,
            issuetyp,
            count(ifn(_type_ = 'T', 1, .)) as nobs,
            count(ifn(_type_ = 'N', 1, .)) as nobsnew,
            count(ifn(_type_ = 'M', 1, .)) as nobsmdf,
            (calculated nobs - calculated nobsnew - calculated nobsmdf) as nobsrpt
        from _presum
        group by site
        ;
    quit;

    data _dvpSiteSummary1;
        set _dvpSiteSummary0;
        length count $40;
        %if &compare = N %then
        count = strip(put(nobs, best.));
        %else
        count = strip(put(nobs, best.)) || '/' ||strip(put(nobsnew, best.)) || '/' || strip(put(nobsmdf, best.)) || '/'
                ||strip(put(nobsrpt, best.));
        ;
        keep site nsubject issuetypn issuetyp count;
    run;
    
    proc sort data = _dvpSiteSummary1; by site; run;

    proc transpose data = _dvpSiteSummary1 out = _dvpSiteSummary2(drop = _:) prefix = CNT_;
        by site nsubject;
        id issuetypn;
        idlabel issuetyp;
        var count;
    run;

    data _dvpSiteSummary3;
        set _mkIssTyp _dvpSiteSummary2;

        length nobs nobsnew nobsmdf nobsrpt 8;

        nobs    = 0;
        nobsnew = 0;
        nobsmdf = 0;
        nobsrpt = 0;

        array cnt{*} CNT_:;
        %if &compare = N %then %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1  %end;
        ;
        %end;
        %else %do;
        array cntn1{*} %do i = 1 %to &nIssueType; CNT_&i._1 %end;;
        array cntn2{*} %do i = 1 %to &nIssueType; CNT_&i._2 %end;;
        array cntn3{*} %do i = 1 %to &nIssueType; CNT_&i._3 %end;;
        array cntn4{*} %do i = 1 %to &nIssueType; CNT_&i._4 %end;;
        %end;
        ;
        do i = 1 to dim(cnt);
            %if &compare = N %then %do;
            cnt[i]   = coalescec(cnt[i], '0');
            cntn1[i] = input(cnt[i], best.);
            nobs     = nobs + cntn1[i];
            %end;
            %else %do;
            cnt[i]    = coalescec(cnt[i], '0/0/0/0');
            cntn1[i]  = input(scan(cnt[i], 1, '/'), best.);
            cntn2[i]  = input(scan(cnt[i], 2, '/'), best.);
            cntn3[i]  = input(scan(cnt[i], 3, '/'), best.);
            cntn4[i]  = input(scan(cnt[i], 4, '/'), best.);
            nobs      = nobs + cntn1[i];
            nobsnew   = nobsnew + cntn2[i];
            nobsmdf   = nobsmdf + cntn3[i];
            nobsrpt   = nobsrpt + cntn4[i];
            %end;
            ;
        end;
        drop i;
        %do i = 1 %to &nIssueType; drop CNT_&i;  %end;
    run;

    proc sort data = _dvpSiteSummary3 out = &siteSummaryDset;
        by site;
        where
        %if &bysite = Y %then
        site ^= "&allSiteTXT";
        %else 
        site = "&allSiteTXT";
        ;
    run;
    %end;


%mend dvpSummary;
