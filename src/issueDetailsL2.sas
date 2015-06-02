/*
    Program Name: issueDetailsL2L2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/10

    Put all issue in single sheet in plain structure.
*/

/**************************************************************************************************************
REVISION HISTORY:

2014/03/10 Ken Cao: Add a issue detail sheet to all data for individual issue. Each issue can be 
                    linked from issue summary sheet.

2014/03/13 Ken Cao: Change the destination location when user click to "Go Back To Issue Summary Sheet" from  
                    summary sheet header to the cell of the issue.

2014/03/28 Ken Cao: Hide (rather than remove) record ID when reviewOnly is set to N.

2014/09/12 Ken Cao: Only output specified site.

***************************************************************************************************************/


%macro issueDetailsL2(site, cat);
    
    %local nIssue;
    %local ALLissueList;
    %local i;
    %local returncol;
    %local returnrow;
    %local lastTitleLine;
    %local issueStartRow;
    %local issueEndRow;
    %local issueStartCol;
    %local issueEndCol;
    %local issueHeaderHeight;
    %local nobs;
    %local issueType;
    %local printSdset;
    %local sdsetOccupiedLineNum;
    %local linkOnSubject;
    %local nvar;

    %let cat = %upcase(&cat);
    %let returncol = 2;

   
    data _ALLissue;
        set &subjectIssueSummaryDset;
        where site="&site" 
        %if &cat = ALL %then
        and nobs > 0;
        %else %if &cat = NEW %then
        and nobsnew > 0;
        %else %if &cat = MODIFIED %then
        and nobsmdf > 0;
        %else %if &cat = REPEAT %then
        and nobsrpt > 0;
        ;
        keep issueid &subjectVar nrefdset refdsets RefDsetrangeName;
        %if "%upcase(&subjectVar)" ^= 'SUBJECT' %then %do;
        length &subjectVar $255;
        &subjectVar = subject;
        %end;
    run;

    %getIssueList(_ALLissue);
    
    title; footnote;

    ods tagsets.excelxp
    options(
        sheet_name            = "Issue Details"
        sheet_interval        = 'none' 
        frozen_headers        = 'no'
        absolute_Column_Width = '30'
        skip_space            = '2, 0, 1, 1, 1'
        %if &reviewonly = N %then
        hidden_columns        = '1';
    );

    * print legend;
    %legend(%if &cat = ALL %then Y; %else N;);

    * initialization of start/end row #;
    %let issueStartRow = %eval(&lastTitleLine + 2); /* start row number of next issue */
    %let issueEndRow   = 0; /* end row number of current issue */
    %let issueStartCol = 1;
    %if &reviewonly = Y %then %let issueEndCol   = 1;
    %else %let issueEndCol = 2;
    %let issueHeaderHeight = 3;

    %do i = 1 %to &nIssue;
        %let issueDset = %upcase(%scan(&ALLissueList, &i, ' '));
        
        data __prt0;
            length issueid $32 RefDsetrangeName $33 &subjectVar $255 nrefdset 8;
            if _n_ = 1 then do;
                declare hash h (dataset:'_ALLissue');
                rc = h.defineKey('issueID', "&subjectVar");
                rc = h.defineData('RefDsetrangeName', 'nrefdset');
                rc = h.defineDone();
                call missing(issueID, &subjectVar, RefDsetrangeName, nrefdset);
            end;
            set &pdatalibrf..&issueDset(rename=(&subjectVar=in_&subjectVar));
            where 1
            and __deleted = ' '
            %if %length(&subjects) > 0 %then
            and findw(strip("&subjects"), strip(in_&subjectVar), '@') > 0;
/*            %if &bySite = Y %then*/
            /* Ken Cao on 2014/09/12: only output specified site */
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
            issueid     = "&issueDset";
            &subjectVar = In_&subjectVar;
            rc = h.find();
            if nrefdset > 0 then do;
                &subjectVar = "=HYPERLINK("""||"#'Reference Sheet'!"||strip(RefDsetrangeName)||""", """||strip(in_&subjectvar)||""")";;;
                call symput('linkOnSubject', 'Y');
            end;
            else do;
                &subjectVar = in_&subjectVar;
                call symput('linkOnSubject', 'N');
            end;

            * remove last version record ID ... from _diff2_;
            if index(_diff2_, '0A'x) > 0 then _diff2_ = substr(_diff2_, index(_diff2_, '0A'x));

            drop rc RefDsetrangeName issueid  in_&subjectVar;
        run;

        %getNvar(&issueDset); 
        %getDsetInfo(indata=__prt0, getNOBS=Y);

        %if &nobs = 0 %then %return;

        %let issueEndCol   = %eval(&nvar + 1 + 1); /* 1: record ID. 1: Q2 comment */
        %if &compare = Y %then %let issueEndCol = %eval(&issueEndCol + 2); /* 2: type and modification details */
        %let issueEndRow   = %eval(&issueStartRow + &issueHeaderHeight + &nobs - 1);
        
        proc sql;
            insert into &namingRangeDset (sheet, rangename, startrow, endrow, startcol, endcol, comment)
            values(
                    "Issue Details",
                    "&issueDset",
                    &issueStartRow,
                    &issueEndRow,
                    &issueStartCol,
                    &issueEndCol,
                    "Issue Dataset &issueDset in Worksheet 'Issue Details'"
                   );
        quit;



        %let issueStartRow = %eval(&issueEndRow + 3);

        %getReturnRowIssueD(&issueDset);

        %printIssueDset
        (
            issuedata         = __prt0, 
            issueid           = &issueDset,
            displaySubjectVar = Y,
            linksheet         = %str(Issue Summary),
            linkloc           = %str(R&returnrow.C&returncol),
            linktext          = %str(Go Back To Issue Summary Sheet),
            useColorCode      = %if &cat = ALL %then Y ; %else N;,
            linkOnSubject     = &linkOnSubject
        );

    %end;
%mend issueDetailsL2;
