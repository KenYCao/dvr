/*
    Program Name: deletedIssues.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/20

    Revision History:

    Ken Cao on 2014/09/12: Only output specified site.
*/

%macro deletedIssues(site, cat);

    %local ndeletion;
    %local ALLissueList;
    %local nIssue;
    %local i;
    %local issueDset;
    %local returncol;
    %local returnrow;
    %local startrow;
    %local endrow;
    %local startcol;
    %local endcol;
    %local headerHeight;
    %local nvar;
    %local nobs;
    %local indexTBLstartRow;
    %local lastTitleLine;

    %if &reviewonly = N %then %let returncol = 2;
    %else %let returncol = 1;

    %let cat = %upcase(&cat);


    * remove issues without a deleted record;
    data _deletion;
        set &deletedIssueDset;
        where site = "&site"
        /*
        %if %length(&subjects) > 0 %then 
        and findw(strip("&subjects"), strip((upcase(subject))), '@') > 0;
        */
        ;
        %if &cat = ALL %then
        ndeleted = nobs;
        %else %if &cat = NEW %then
        ndeleted = nobsnew;
        %else %if &cat = MODIFIED %then
        ndeleted = nobsmdf;
        %else %if &cat = REPEAT %then
        ndeleted = nobsrpt;
        ;
        if ndeleted > 0;
    run;

    %getDsetInfo(indata=_deletion, getNOBS=Y);
    %let ndeletion = &nobs;
    
    **********************************************************************************************;
    * gathering all issue ID with deleted record.
    **********************************************************************************************;
    %getIssueList(_deletion);

    title; footnote;

    ods tagsets.excelxp
    options(
        sheet_name            = "Deleted Issues"
        sheet_interval        = 'none' 
        frozen_headers        = 'no'
        absolute_Column_Width = '28'
        skip_space            = '2, 0, 1, 1, 1'
    );

    %if &nIssue = 0 %then
        %do;
            data _noDeletedIssue;
                length a $255;
                a = ' '; output;
                a = 'No Deleted Issues'; output;
            run;

            proc report data = _noDeletedIssue nowd noheader;
            run;

            %return;
        %end;

    * print legend;
    %legend(%if &cat = ALL %then Y; %else N;);

    %let indexTBLstartRow = %eval(&lastTitleLine + 2);


    **********************************************************************************************;
    * print index table
    **********************************************************************************************;
    /*
    data __index;
        set _deletion nobs=_nobs_;
        ndeleted2 = lag(ndeleted);
        retain _issueheadernum _1stissuestartnum;
        if _n_ = 1 then
            do;
                _indexstartnum     = &indexTBLstartRow; 
                _indexheadernum    = 1;
                _indexendnum       = _indexstartnum  + _nobs_ + _indexheadernum - 1; 
                _1stissuestartnum  = _indexendnum + 2; 
                _issueheadernum    = 3; 
            end;

        retain _issuestartnum;
        if _n_ = 1 then _issuestartnum = _1stissuestartnum;
        else _issuestartnum = _issuestartnum + _issueheadernum + ndeleted2 + 2;
        _issueendnum = _issuestartnum + ndeleted + _issueheadernum - 1;

        length _range $40 hplink $256;
        _range = "R"||strip(put(_issuestartnum, best.))||"C1"||':R'||strip(put(_issueendnum, best.))||"C1";
        
        hplink = "=HYPERLINK("""||"#'Deleted Issues'!"||strip(_range)||""", """||strip(issueid)||""")";
    run;
    */

    data _IDXdel;
        set _deletion;
        hplink = "=HYPERLINK("""||"#'Deleted Issues'!"||strip(issueid)||""", """||strip(issueid)||""")";
    run;

    proc report data = _IDXdel nowd;
        column hplink ndeleted;
        define hplink / 'Issue ID' style(column) = [textdecoration=underline foreground=blue fontsize=10pt font=fonts('font')];
        define ndeleted / '# of Deleted Records by User';
    run;


    **********************************************************************************************;
    * print each issue datasets
    **********************************************************************************************;

    %let startRow     = %eval(&indexTBLstartRow + &ndeletion + 2);
    %let EndRow       = 0; /* end row number of current issue */
    %let StartCol     = 1;
    %let EndCol       = 1;
    %let HeaderHeight = 3;

    %do i = 1 %to &nIssue;
        %let issueDset = %upcase(%scan(&ALLissueList, &i, " "));

        data __prt0;
            set &pdatalibrf..&issueDset;
            where __deleted = 'Y'
            %if %length(&subjects) > 0 %then 
            and findw(strip("&subjects"), strip(upcase(&subjectVar)), '@') > 0;
/*            %if &bySite = Y %then*/
            /* Ken Cao on 2013/09/12: output only specified site */
            %if %length(&sitevar) > 0 and %length(&sites) > 0 %then
            and &sitevar = "&site";
            %if &cat = ALL %then
            and 1;
            %else %if &cat = NEW %then
            and _type_ = 'N';
            %else %if &cat = MODIFIED %then
            and _type_ = 'M';
            %else %if &cat = REPEAT %then
            and _type_ = ' ';
            ;
        run;

        * get return row number of the issue;
        data _null_;
            set _IDXdel;
            if upcase(issueid) = "&issueDset" then
                do;
                    returnrow = _n_ + &indexTBLstartRow;
                    call symput('returnrow', strip(put(returnrow, best.)));
                    stop;
                end;
        run;

        %getDsetInfo(indata=__prt0, getNOBS=Y);
        
        %if &nobs = 0 %then %return;

        %getNvar(&issueDset);

        %let endRow   = %eval(&startRow + &HeaderHeight + &nobs - 1);
        %let endCol   = %eval(&nvar + 1 + 1 - 1); /* 1: record ID. 1: Q2 comment. -1: subject*/
        %if &compare = Y %then %let endCol = %eval(&endCol + 2); /* 2: type and modification details */

        proc sql;
            insert into &namingRangeDset (sheet, rangename, startrow, endrow, startcol, endcol, comment)
            values(
                    "Deleted Issues",
                    "&issueDset",
                    &StartRow,
                    &EndRow,
                    &StartCol,
                    &EndCol,
                    "Issue Dataset &issueDset in Worksheet 'Deleted Issues'"
                   );
        quit;

        %let startRow = %eval(&endRow + 3);

        %printIssueDset
        (
            issuedata         = __prt0, 
            issueid           = &issueDset,
            displaySubjectVar = Y,
            linksheet         = %str(Deleted Issues),
            linkloc           = %str(R&returnrow.C&returncol),
            linktext          = %str(Go Back To Index Table),
            useColorCode      = %if &cat = ALL %then Y ; %else N;
        );

    %end;

%mend deletedIssues;
