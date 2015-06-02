/*
    Program Name: printIssueDset.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/07


    print issue dataset

*/


/************************************************************************************************;
Revision History

2014/03/10 Ken Cao: Add column 'Q2 COMMENT' to the end of each issue dataset.
2014/03/26 Ken Cao: By default variable label is displayed.
2915/02/16 Ken Cao: Highlight changed variable for modified record.

************************************************************************************************/;


%macro printIssueDset(issuedata=, issueid=, displaySubjectVar=, linksheet=, linkloc=, linktext=, useColorCode=, linkOnSubject=, linkOnIssueID=);

    %local linkOnIssueID;
    %local subject;
    %local refRangeName;
    %local refDsets;
    %local msg;
    %local sdset;
    %local sdsetlbl;
    %local issueType;
    %local nobs;
    %local nflyoverVar;
    %local i;
    
    /*
        Ken on 2014/04/21:
        temporary solution.
        &linkOnSubject = Y and &displaySubjectVar = N ===> subject worksheet.
    */
    /*%if %upcase(&linkOnSubject) = Y and %upcase(&displaySubjectVar) = N %then %let linkOnIssueID = Y;*/

    %let linkOnIssueID = %sysfunc(coalescec(&linkOnIssueID, N));


    %if &linkOnIssueID = Y %then %do;
        data _null_;
            set &issuedata;
            if index(upcase(&subjectvar), '=HYPERLINK(') = 1 then
            &subjectvar = scan(scan(&subjectvar, 2, ','),2, '"''()');
            call symput('subject', strip(&subjectVar));
            stop;
        run;
        %getRefRangeName(&issueID, &subject);
    %end;
    %getRefDsets(&issueID);



    * returns formatted issue dataset(_issueDset) and flyover dataset(_flyover);
    %issueDsetPrintSetup(indata=&issuedata, issueID=&issueID, out=_issueDset, outFlyover=_flyOver);

    %let linkOnSubject = %upcase(&linkOnSubject);

    * get issue meta information (message/source dataset/issue type);
    %getIssueMeta(&issueID, getMsg = Y, getSdset = Y, getSdsetlbl = Y, getIssueType = Y);

    %getDsetInfo(indata = _flyover, getNOBS=Y);
    %let nflyoverVar = &nobs;
    
    %do i = 1 %to &nflyoverVar ;
        %local var&i;
        %local label&i;
        %local flyover&i;
    %end;

    data _null_;
        set _flyOver;
        call symput('var'||strip(put(_n_, best.)), strip(varname));
        call symput('label'||strip(put(_n_, best.)), strip(label));
        call symput('flyover'||strip(put(_n_, best.)), strip(flyover));
    run;

    ods tagsets.excelxp options(absolute_Column_Width = '30');

    proc report data = _issueDset nowd split = "&splitchar"
    style(column) = [tagattr='format:@'] 
/*    style(header) = [background=&issueDsetHDRbgcolor fontweight=bold]*/
    ;
        /*
        column 
        __recID
        %do i = 1 %to &nglb; &&glbvar&i  %end;
        %do i = 1 %to &nkey; &&keyvar&i  %end;
        %do i = 1 %to &nrep; &&repvar&i  %end;
        %if &compare = Y %then _type_ _diff2_ ;
        __q2cmnt __odd 
        ;
        */

        define __recID / 'Record ID';

        %if &compare = Y %then %do;
        define _type_/'N=New#M=Modified' style(header)=[foreground=green];
        define _diff2_/ 'Modification Detail' style(column)=[tagattr='format:general'] style(header)=[foreground=green];
        %end;

        %do i = 1 %to &nflyoverVar;
        define &&var&i / "&&label&i" style(header)=[flyover="&&flyover&i"];
        %end;
        
        %if &linkOnSubject = Y %then %do;
        define &subjectVar / style(column)=[foreground=blue background=white textdecoration=underline fontsize=10pt font=fonts('font')];
        define &subjectVar / "&splitchar.Click to View Reference Data";
        %end;

        %if &displaySubjectVar = N %then %do;
        define &subjectvar / noprint;
        %end;

        define _all_ / display;

        define __q2cmnt / 'Q2 COMMENT' style(column)=[tagattr='format:general'] ;
        define __odd / noprint;
        define _diff3_ / noprint;
        define _mdfnum_ / noprint display;


        %if &compare = N %then %do;
        define _type_ / noprint;
        define _diff2_ / noprint;
        %end;
        %else %do;
            define _numeric_ / display;
        %end;


        compute before _page_ / style=header{just = l background = colors('skipcolor') foreground = blue
                                             font = fonts('font') fontsize = 10pt textdecoration=underline};
            %if &linkOnIssueID = Y %then
            line "=HYPERLINK(""#'Reference Sheet'!&refRangeName"", ""&issueid (&issueType) - Click to view reference dataset: &refDsets"")";
            %else %if %length(&refDsets) > 0 %then 
            line "&odsEscapeChar.S={foreground=colors('titlecolor') fontweight=bold}&issueid (&issueType) - Reference Datasets: &refDsets";
            %else
            line "&odsEscapeChar.S={foreground=colors('titlecolor') fontweight=bold}&issueid (&issueType)";
            ;
            line "&odsEscapeChar.S={foreground=colors('titlecolor') fontweight=light}Source Dataset(s): &sdset(&sdsetlbl) &odsescapechar.n&msg";
        endcomp;

        compute after _page_ / style=header{just = l font = fonts('font') fontsize = 10pt height = 15pt
                                            background = white foreground = blue textdecoration = underline};
            line "=HYPERLINK(""#'&linksheet'!&linkloc"", ""&linkText"")";
        endcomp;


        %if &compare = Y and &useColorCode = Y %then %do;
        compute _type_;
            if _type_ = 'M' then call define(_row_, "style", "style=[backgroundcolor=&mdfcolor]");
            if _type_ = 'N' then call define(_row_, "style", "style=[backgroundcolor=&newcolor]");
        endcomp;
        %end;

        ** Ken Cao on 2015/02/12: Highlight changed variable for modified record.;
        %if &compare = Y and &reviewonly = Y %then %do;
            compute _mdfnum_;
                length __seg__ $512;
                length __varname__ $32;
                length __value__ $256;
                length __flyover__ $512;
                if _type_ = 'M' then do i = 1 to _mdfnum_;
                    __seg__     = scan(_diff3_, i, '@');
                    __varname__ = scan(__seg__, 1, ':');
                    __value__   = substr(__seg__, index(__seg__, ':')+2);
                    
                    if __value__ = ' ' then __value__ = '{BLANK}';
                    __value__ = translate(__value__, "''", "'");
                    __value__ = prxchange('s/</&lt;/', -1, __value__);
                    __value__ = prxchange('s/>/&gt;/', -1, __value__);
                    __flyover__ = "flyover='"||strip(__value__)||"'";
                    call define(strip(__varname__), 'style', "style=[backgroundcolor=&mdfvarcolor "||strip(__flyover__)||']');
                end;
            endcomp;
        %end;

    run;
    

%mend printIssueDset;
