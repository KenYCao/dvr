/*
    Program Name: printSubject.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/14

    Print all issue datasets of a subject

*/


%macro printSubject(subject, cat);
    
    %local returncol;
    %local returnrow;
    %local nIssue;
    %local ALLissueList;
    %local i;
    %local lastTitleLine;
    %local indexTBLstartRow;
    %local issueStartRow;
    %local issueStartCol;
    %local issueEndRow;
    %local issueEndCol;
    %local issueHeaderHeight;
    %local nobs;
    %local nvar;
    %local refdsets;
    %local linkOnSubject;

    %let cat = %upcase(&cat);

    %if &reviewonly = Y %then %let returncol = 2;
    %else %let returncol = 3;

    /*
    %if &compare = Y %then %let subjectIndexStartRow = 8;
    %else %let subjectIndexStartRow = 5;
    */


    ****************************************************************************************;
    * Lgend lines:
    * * * Sample of new issue records
    * * * Sample of modified records
    ****************************************************************************************;

    %legend(%if &cat = ALL %then Y; %else N;);
    %let indexTBLstartRow = %eval(&lastTitleLine + 2);



    ****************************************************************************************;
    * Index table for individual subject
    ****************************************************************************************;

    %subjectIndex(site = &site, subject = &&subject&i, indexStartRow = &indexTBLstartRow, cat = &cat);


    proc sort data = __IDXsubj; by issuetypn issueid; run; /* _index are returned from macro Subject Index TBL*/

    data _ALLissue;
        set &subjectIssueSummaryDset;
        where subject = "&subject";
        %if &cat = NEW %then
        nobs = nobsnew;
        %else %if &cat = MODIFIED %then
        nobs = nobsmdf;
        %else %if &cat = REPEAT %then
        nobs = nobsrpt;
        ;
        if nobs > 0;
        keep issueid &subjectVar nrefdset RefDsetrangeName;
        %if "%upcase(&subjectVar)" ^= 'SUBJECT' %then %do;
        length &subjectVar $255;
        &subjectVar = subject;
        %end;
    run;

/*    %getIssueList(&dvpConfigDset(where=(nobs>0)));*/
    %getIssueList(_ALLissue);


    * initialization of start/end row #;
    %let issueStartRow     = %eval(&lastTitleLine + 2 /*index table start row*/+ &nIssue + 2 /* # of rows of index table */+ 1); 
    %let issueEndRow       = 0; /* end row number of current issue */
    /*
    %if &reviewonly = Y %then %let issueStartCol = 1;
    %else %let issueStartCol = 2;
    */
    %let issueStartCol  = 1;
    %if &reviewonly = Y %then %let issueEndCol = 1;
    %else %let issueEndCol = 2;
    %let issueHeaderHeight = 3;

    %do i = 1 %to &nIssue;
        %let issueDset = %scan(&ALLissueList, &i, ' ');

        data _null_;
            set __IDXsubj;
            if issueid = "&issueDset" then 
                do;
                    returnrow = &indexTBLstartRow + _n_ + 2 - 1; /* 2: # of header lines of index table*/
                    call symput('returnrow', strip(put(returnrow, best.)));
                    stop;
                end;
        run;

        data __prt0;
            length issueid $32 RefDsetrangeName $33 &subjectVar $255 nrefdset 8;
            if _n_ = 1 then do;
                declare hash h (dataset:'_ALLissue');
                rc = h.defineKey('issueID', "&subjectVar");
                rc = h.defineData('RefDsetrangeName', 'nrefdset');
                rc = h.defineDone();
                call missing(issueID, &subjectVar, RefDsetrangeName, nrefdset);
            end;
            set &pdatalibrf..&issueDset(rename=(&subjectVar = in_&subjectVar));
            where in_&subjectVar= "&subject" 
            and __deleted = ' ' /* excluded records that was logically deleted */
            %if &cat = ALL %then
            and 1;
            %else %if &cat = NEW %then
            and _type_ = 'N';
            %else %if &cat = MODIFIED %then
            and _type_ = 'M';
            %else %if &cat = REPEAT %then
            and _type_ = ' ';
            ;
            issueid = "&issueDset";
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

            drop rc RefDsetrangeName issueid in_&subjectVar;
        run;

        %getDsetInfo(indata=__prt0, getNOBS=Y);
        %getNvar(&issueDset);

        %let issueEndRow   = %eval(&issueStartRow + &issueHeaderHeight + &nobs - 1);
        %let issueEndCol   = %eval(&nvar + 1 + 1 - 1); /* 1: record ID. 1: Q2 comment. -1: subject*/
        %if &compare = Y %then %let issueEndCol = %eval(&issueEndCol + 2); /* 2: type and modification details */

        proc sql;
            insert into &namingRangeDset (sheet, rangename, startrow, endrow, startcol, endcol, comment)
            values(
                    "&subject",
                    "&issueDset",
                    &issueStartRow,
                    &issueEndRow,
                    &issueStartCol,
                    &issueEndCol,
                    "Issue Dataset &issueDset in Worksheet '&subject'"
                   );
        quit;

        %let issueStartRow = %eval(&issueEndRow + 3);

        %getRefDsets(&issueDset);

        %printIssueDset
        (
            issuedata         = __prt0, 
            issueid           = &issueDset,
            displaySubjectVar = N,
            linksheet         = %str(&subject),
            linkloc           = %str(R&returnrow.C&returncol),
            linktext          = %str(Go Back To Index Table),
            useColorCode      = %if &cat = ALL %then Y ; %else N;,
            linkOnIssueID     = %if %length(&refDsets) > 0 %then Y; %else N;
        );
    %end;

%mend printSubject;
