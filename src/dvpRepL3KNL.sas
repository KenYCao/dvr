/*
    Program Name: dvpRepL3KNL.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Author: 2014/07/03

    Generate data validation report layout 3.


    Revision History:

    Ken Cao on 2014/09/12: Fix a bug in collecting issue dataset (only output specified site)
    Ken Cao on 2014/11/18: Fix a bug introduced in 2014/09/12 (output filter for site).
*/


%macro dvpRepL3KNL(cat=, outputpath=, site=);

    %local outputpath;
    %local nIssue;
    %local ALLissueList;
    %local date;
    %local time;
    %local nameprefixFileName;
    %local filename;
    %local i;
    %local issueDset;
    %local keyvars;
    %local nkey;
    %local maxnkey;
    %local j;
    %local keyvar;
    %local callFile;
    %local nIssueType;
    %local nqstat;



    %let cat    = %upcase(&cat);
    %let nIssue = 0;

    data _anyIssue;
        set &issueSummaryDset;
        where site = "&site"
        %if &cat = ALL %then
        and nobs > 0;
        %else %if &cat = NEW %then
        and nobsnew > 0;
        %else %if &cat = MODIFIED %then 
        and nobsmdf > 0;
        %else %if &cat = REPEAT %then 
        and nobsrpt > 0;
        ;
    run;

    %getIssueList(_anyIssue);

    data _dvrL3_0;
        length __recid $64 __keyid $64 issueid $32
               sdset $200 /*key variables inserted here*/ 
               sdsetlbl $1024 fieldname $1024 __finding $1024 
               __q2cmnt $1024 __initdt $40 __clientcmnt $1024
               issueTyp $255 issueTypn 8 _type_ $1 _diff2_ $32767 __groupid $255 __querystat $1024;
        call missing(__recid,__keyid, issueid, sdset, sdsetlbl, fieldname, __finding, __q2cmnt, __initdt, __clientcmnt, issueTyp, 
                issueTyp, issueTypn, _type_, _diff2_, __groupid, __querystat);
        if 0;
    run;

    %let maxnkey = 0; /* initialization */

    %do i = 1 %to &nIssue;
        %let issueDset = %scan(&ALLissueList, &i, ' ');

        data _null_;
            set _L3config;
            where issueid = "&issueDset";
            call symput("keyvars", strip(keyvars));
            if keyvars = ' ' then nkey = 0;
            else nkey = countc(strip(keyvars), " ") + 1;
            call symput('nkey', strip(put(nkey, best.)));
        run;
    
        data _L3tmp;
            set &pdatalibrf..&issueDset;
            where __deleted = ' '
            /* Ken on 2014/09/12: only output specified site */
            /* Ken Cao on 2014/11/19: remove site filter when user doesn't specify a filter */
            %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
            and &sitevar = "&site";
            %if %length(&subjects) > 0 %then 
            and findw(strip("&subjects"), strip(upcase(&subjectVar)), '@') > 0;
            %if &cat = ALL %then
            and 1;
            %else %if &cat = NEW %then
            and _type_ = 'N';
            %else %if &cat = MODIFIED %then
            and _type_ = 'M';
            %else %if &cat = REPEAT %then
            and _type_ = ' ';
            ;
            keep
                __recid __keyid __groupid issueid __finding
                &subjectvar &keyvars 
                _type_ _diff2_ __q2cmnt __initdt __querystat __clientcmnt;
            ;

            length issueid $32;
            issueid = "&issueDset";

            %do j = 1 %to &nkey;
                %let keyvar = %scan(&keyvars, &j, " ");
                rename &keyvar = KEYVAR_&j;
            %end;
        run;

        data _dvrL3_0;
            set _dvrL3_0 _L3tmp;
        run;

        %let maxnkey = %sysfunc(max(&maxnkey, &nkey));
        %let keyvars = ;
        %let nkey = 0;
        %let keyvar =;
    %end;

    data _dvrL3;
        length issueid $32 sdset $255 sdsetlbl $1024 fieldname $1024 issueTyp $255 issueTypn 8 ; 
        if _n_ = 1 then do;
            declare hash h (dataset:'_L3config');
            rc = h.defineKey('issueid');
            rc = h.defineData('sdset', 'sdsetlbl', 'fieldname', 'issueTyp', 'issueTypn' );
            rc = h.defineDone();
            call missing(issueid, sdset, sdsetlbl, issueTyp, issueTypn);
        end;
        set _dvrL3_0;
        rc = h.find();

        * temporary filters. to be removed;
        if rc = 0;


        * deal with new line character;
        __finding   = linefeed(__finding, "&odsEscapeChar");
        fieldname   = linefeed(fieldname, "&odsEscapeChar");
        sdset       = linefeed(sdset,     "&odsEscapeChar");
        sdsetlbl    = linefeed(sdsetlbl,  "&odsEscapeChar");


    run;

    %if &nIssue = 0 %then %do;
        data _dummy;
            length &subjectvar $255;
            _dummy = ' ';
            &subjectvar = ' ' ;
        run;

        data _dvrL3;
            set _dvrL3 _dummy;
            drop _dummy;
        run;
    %end;

    proc sort data = _dvrL3;
        by sdset &subjectvar __groupid;
    run;

    data _dvrL3rep;
        set _dvrL3;
            by sdset &subjectvar __groupid;
        length __grp $1024;
        __ord + 1;
        if first.&subjectvar then __ord = 1;
        if __groupid = ' ' then __groupid = strip(put(__ord, best.));
        
        /*
        %if &reviewonly = Y %then %do;
        __grp = sdset||'-'||issueid||'-'||&subjectvar||'-'||__groupid;
        %end;
        %else %do;
        __grp = &subjectvar||sdset||'-'||issueid||'-'||'-'||__groupid;
        %end;
        */

        __grp = sdset||'-'||issueid||'-'||&subjectvar||'-'||__groupid;

        * avoid order null variable ;
        /*
        if __q2cmnt = ' ' then __q2cmnt = '0A'x;
        if __clientcmnt = ' ' then __clientcmnt = '0A'x;
        */
        array ___char___{*} _character_;
        do ___i___ = 1 to dim(___char___);
            if ___char___[___i___] = ' ' then ___char___[___i___] = '0A'x;
        end;
        drop ___i___;
    run;

    * setup ods tagsets.excelxp;
    %let nameprefixFileName = %str(Data_Review_Issue_Tracker_&studyid2);
/*    %setupODS(cat=&cat, outputpath=&outputpath, site=&site);*/

    %getDateTime;
    %let filename = &nameprefixFileName._%upcase(&cat)_&date.T&time;

    %if &bySite = Y %then %do;
        %if &compare = Y %then %do;
            %newFolder(foldername = &cat, parentdir = &outputpath);
            %let outputpath = %str(&outputpath\&cat);
        %end;
        %let filename = %str(&nameprefixFileName._SITE_&site._%upcase(&cat)_&date.T&time);
    %end;

    ods _all_ close;
    title; footnote;
    title "Q2 DM Report - Data Review Issue Tracker";
    title2 "Generated on &date.T&time";
    * create new tagsets.excelxp output;
    * Ken on 2014/04/15: create a report in temprary directory first;
    ods tagsets.excelxp path = "&tempDir"  file = "&filename..xml"  style = dvrstyle
    options(
        orientation='landscape'
        autofit_height="yes"
        wraptext="yes"
        fittopage="yes"
        gridlines="no"
        embedded_titles='yes'
        embedded_footnotes='yes'
        frozen_headers='yes'
        %if &reviewonly = N %then
        hidden_columns= '1';

    );

    /********************************************************;
     * Summary Sheet
     ********************************************************/;
    %let nIssueType = %sysfunc(countc(&allIssueType, @));
    %let nIssueType = %eval(&nIssueType + 1);
    %do i = 1 %to &nIssueType;
        %local issueType&i;
        %let issueType&i = %scan(&allIssueType, &i, @);
    %end;

    data _issueTypSum;
        set &subjectSummaryDset;
        where site = "&site";
        length %do i = 1 %to &&nIssueType; issueTyp_&i 8 %end;;
        array cnt1{*} cnt_:;
        array cnt2{*} issueTyp_:;
        do i = 1 to dim(cnt1);
            if scan(vname(cnt1[i]), -1, "_") ^= '1' then continue;
            __num = input(strip(scan(vname(cnt1[i]), 2, "_")), best.);
            cnt2[__num] = cnt1[i];
        end;
        %do i = 1 %to &&nIssueType;
            label issueTyp_&i = "&&issueType&i";
        %end;
        keep subject issueTyp_:;
    run;

    data _qstatSum;
        set &QstatSummaryDset;
        where site = "&site";
        keep subject cnt__:;
        array cnt{*} cnt__:;
        nvar = dim(cnt);
        call symput('nqstat',strip(put(nvar, best.)));
    run;

    data __sumL3;
        merge _issueTypSum _qstatSum;
            by subject;
        __odd = strip(put(mod(_n_, 2), best.));
    run;
    
    proc sort data = __sumL3; by subject; run;
    
    title3 "&runid";
    ods tagsets.excelxp options(sheet_name = "Summary Sheet" );
    proc report data = __sumL3 nowd split='@'
    style(column) = [tagattr='format:@' bordercolor=#000000 cellwidth=1.3in]
    style(report) = [bordercolor=#000000] 
    ;
        column subject 
            ('Issue Type' %do i = 1 %to &nIssueType; issueTyp_&i %end;)
            ("Query Status" %do i = 1 %to &nqstat; CNT__&i %end;)
            __odd
        ;
        define subject / 'Subject' order;
        define __odd / noprint;

        compute __odd;
            if __odd = '0' then call define(_row_, "style", "style=[backgroundcolor=colors('skipcolor')  fontsize=10pt font=fonts('font')]");
        endcomp;
    run;


    /********************************************************;
     * DM Findings 
     ********************************************************/;
    title3 "&runid";
    %if &compare = Y %then %do;
    title4 "Benchmark: &benchmarkid";
    %end;
    ods tagsets.excelxp options(sheet_name = "DM Findings" );

    proc report data = _dvrL3rep nowd  spanrows split='\'
    style(column) = [tagattr='format:@' bordercolor=#000000]
    style(report) = [bordercolor=#000000] 
    ;
        column

            __grp
            __recid
            __keyid

            sdset
            issueid 
            issueTyp
            &subjectvar
            %do i = 1 %to &maxnkey;
            keyvar_&i
            %end;
            sdsetlbl
            fieldname
            __finding
            __q2cmnt
            __initdt
            __querystat
            __clientcmnt
            _type_
            _diff2_
            ;


        define __grp / noprint group;
        define sdset /  'Source' style(column)=[cellwidth=1.0in] order;
        define sdsetlbl / 'CRF Form Name' style(column)=[cellwidth=2.2in] order;
        define fieldname / 'CRF Field Name' style(column)=[cellwidth=2.2in] order;
        define issueid / 'Issue ID' style(column)=[cellwidth=1.5in] order;;
        %if &reviewonly = N %then %do;
        define issueid / noprint;
        %end;
        define issuetyp / 'Issue Severity' style(column)=[cellwidth=1.5in] order;;
        define &subjectvar /'Subj #' style(column)=[cellwidth=1.0in] order;
        define __q2cmnt / 'Q2 Comment'  style(column)=[cellwidth=2.5in] order;
        define __clientcmnt / 'Client Comment' style(column)=[cellwidth=2.5in] order;
        define __querystat / 'Query Status' style(column)=[cellwidth=2.5in] order;


        define __recid / 'Record ID' style(column)=[cellwidth=1.5in];
        /*
        %if &reviewonly = N %then %do;
        define __recid / noprint;
        %end;
        */
        define __keyid / noprint;
        %do i = 1 %to &maxnkey;
        define keyvar_&i/ style(column)=[cellwidth=1.5in];
        %end;
        define __finding / 'Issue/Finding' style(column)=[cellwidth=3.0in] ;
        define __initdt  / 'Initial Report Date' style(column)=[cellwidth=1.0in]; ;

        define _type_ / noprint;
        define _diff2_ / 'Modification Details' style(column)=[cellwidth=2.5in];
        %if &compare = N %then %do;
        define _diff2_ / noprint;
        %end;

        
        /*
        compute before / style=[just=l fontweight=bold foreground=colors('titlecolor') fontsize=10pt font=fonts('font')];
            line "&runid";
            %if &compare = Y %then %do;
            line "Benchmark: &benchmarkid";
            %end;
        endcomp;
        */

        %if &compare = Y and &useColorCode = Y %then %do;
        compute _type_;
            if _type_ = 'M' then call define(_row_, "style", "style=[backgroundcolor=&mdfcolor]");
            if _type_ = 'N' then call define(_row_, "style", "style=[backgroundcolor=&newcolor]");
        endcomp;
        %end;

        %if &nIssue = 0 %then %do;
        compute after / style=[just=c foreground=colors('titlecolor') fontsize=10pt font=fonts('font')];
            line "No Observation";
        endcomp;
        %end;
    run;

    ods tagsets.excelXP close;

    /**********************************
    * save as .xlsx workbook;
    ***********************************/

    * vbscript filename to call sub expCFG2csv;
    %let callFile = &tempDir\callsaveAsxlsx.vbs;

    * delimiter of csv file;
    %let dlm = %str(,);

    data _null_;
        file "&callFile";
        put 'Dim fsObj : Set fsObj = CreateObject("Scripting.FileSystemObject")';
        put "Dim vbsFile : Set vbsFile = fsObj.OpenTextFile(""&rootdir\src\saveAsxlsx.vbs"", 1, False)";
        put 'Dim myFunctionsStr : myFunctionsStr = vbsFile.ReadAll';
        put 'ExecuteGlobal myFunctionsStr';
        put "call saveAS(""&tempDir\&filename..xml"", _";
        put """&outputpath"")"; 
        put 'vbsFile.Close';
        put 'Set vbsFile = Nothing';
        put 'Set fsObj = Nothing';
    run;

    x "'&callFile'";


%mend dvpRepL3KNL;
