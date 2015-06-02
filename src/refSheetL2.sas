/*
    Program Name: refSheet2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/14

    MODIFICATION HISTORY:
    Ken Cao on 2014/11/18: Fix a XML parse issue when reference dataset only contians one variable (TAGSETS.EXCELXP issue).

*/

%macro refSheetL2(site,cat);

    %local StartRow;
    %local EndRow;
    %local StartCol;
    %local EndCol;
    %local HeaderHeight;
    %local nobs;
    %local nRef;
    %local i;
    %local refdsets;
    %local refdset;
    %local nrefdset;
    %local parentIssueID;
    %local subject;
    %local nobsRef;
    %local j;
    %local issueDset;
    %local nVar;
    %local rangeName;
    %local nFlyOverVar;
    %local bgcolor;
    %local cnt;
    %local msg;
    %local issueMSG;

    ** Ken Cao on 2014/11/18: for counting # of variables in reference dataset **;
    %local dsid;
    %local nrefvar;
    %local rc;



    /*
    data _ALLRefDset0;
        set &subjectIssueSummaryDset;
        where site="&site" 
        and nrefDset > 0
        %if &cat = ALL %then
        and nobs > 0;
        %else %if &cat = NEW %then
        and nobsnew > 0;
        %else %if &cat = MODIFIED %then
        and nobsmdf > 0;
        %else %if &cat = REPEAT %then
        and nobsrpt > 0;
        ;
        keep issueid subject;
    run;
    */

    proc sql noprint;
        create table _ALLRefDset as
        select 
            issueid,
            subject,
            refDsetRangeName,
            nrefdset,
            refdsets
        from &subjectIssueSummaryDset
        where site="&site" 
        and nrefDset > 0
        %if &cat = ALL %then
        and nobs > 0;
        %else %if &cat = NEW %then
        and nobsnew > 0;
        %else %if &cat = MODIFIED %then
        and nobsmdf > 0;
        %else %if &cat = REPEAT %then
        and nobsrpt > 0;
        ;
    quit;

    
    %getDsetInfo(indata=_ALLRefDset, getNOBS = Y);
    %let nRef = &nobs;
    

    title; footnote;

    ods tagsets.excelxp
    options(
        sheet_name            = "Reference Sheet"
        sheet_interval        = 'none' 
        frozen_headers        = 'no'
        absolute_Column_Width = '30'
        skip_space            = '2, 0, 1, 1, 1'
        hidden_columns        = '0'

    );

    * if no reference datasets ;
    %if &nRef = 0 %then %do;
        data _noRefDsets;
            length str $255;
            str = 'No Reference Data Available';
        run;
        proc report data = _noRefDsets noheader nowd;
        run;
        %return; 
    %end;



    /*******************************************
    print an index
    *******************************************/
    data _IDXrefsheet;
        set _ALLRefDset;
        length hplink $255;
        hplink = "=HYPERLINK("""||"#'Reference Sheet'!"||strip(refDsetRangeName)||""", """||strip(subject)||""")";;
        keep refdsets issueid subject hplink;
    run;


    proc report data = _IDXrefsheet nowd spanrows;
        column refdsets issueid subject hplink;
        define refdsets / order 'Source Dataset(s)' style(column)=header{vjust=m fontweight=light font=fonts('font')
                                                                         fontsize=10pt foreground=white};
        define issueID / order 'Parent Issue ID' style(column)=[vjust=m];
        define subject / noprint order;
        define hplink / 'Subject' style(column)=[foreground=blue textdecoration=underline fontsize=10pt font=fonts('font')];
        compute before _page_ / style=header{
                                                          just = l 
                                                          font = fonts('font')
                                                      fontsize = 10pt
                                                    background = white 
                                                    foreground = blue 
                                                textdecoration = underline 
                                             };
            line "=HYPERLINK(""#'Issue Summary'!R1C1"", ""Go Back to Issue Summary"")";
        endcomp;
    run;

    %let StartRow = %eval(&nRef + 2 + 2); /* 2: # of rows of index header 2: one row skip after index table */
    %let EndRow = 0;
    %let StartCol = 1;
    %let EndCol = 1;


    %do i = 1 %to &nRef;
        data _null_;
            set _ALLRefDset (firstobs = &i obs = &i);
            call symput('refdsets', strip(refdsets));
            call symput('nrefdset', strip(put(nRefDset, best.)));
            call symput('parentIssueID', strip(issueid));
            call symput('subject', strip(subject));
            call symput('rangeName', strip(refDsetRangeName));
        run;
        
        
        * generate combined referenced datasets;
        %genRefDsets(issueid = &parentIssueID, subject=&subject, out=_refDset, outFlyOver=_flyOver);

        * return NOBS and NVARS of referenced dataset: &nobs and &nvar;
        %getDsetInfo(indata = _refDset, getNOBS = Y, getNVARS = Y);

        * return issue message: &msg ( ---> &issueMSG );
        %getIssueMeta(&parentIssueID, getMsg=Y);
        %let issueMSG = &msg;

        %let nobsRef = &nobs;
        %let EndCol = &nvar;

        %if &nobsRef = 0 %then %do;
            data _dummy;
                __n = 1;
            run;

            data _refDset;
                set _refDset _dummy;
                drop __n;
            run;
        %end;
            

        %let HeaderHeight = 4;
        %if &nobsRef > 0 %then
            %let EndRow = %eval(&StartRow + &HeaderHeight + &nobsRef - 1);
        %else 
            %let EndRow = %eval(&StartRow + &HeaderHeight + 2 - 1);

        proc sql;
            insert into &namingRangeDset (sheet, rangename, startrow, endrow, startcol, endcol, comment)
            values(
                    "Reference Sheet",
                    "&rangeName",
                    &StartRow,
                    &EndRow,
                    &StartCol,
                    &EndCol,
                    "Subject &subject in Reference Datasets &refdsets"
                   );
        quit;

        %getDsetInfo(indata=_flyOver, getNOBS=Y);
        %let nFlyOverVar = &nobs;

        %do j = 1 %to &nflyoverVar ;
            %local var&j;
            %local label&j;
            %local flyover&j;
            %local dsetnum&i;
        %end;

        data _null_;
            set _flyOver;
            call symput('var'||strip(put(_n_, best.)), strip(varname));
            call symput('label'||strip(put(_n_, best.)), strip(label));
            call symput('flyover'||strip(put(_n_, best.)), strip(flyover));
            call symput('dsetnum'||strip(put(_n_, best.)), strip(put(dsetNum, best.)));
        run;


        ** Ken Cao on 2014/11/18: Count # of variables in dataset _refDset **;
        %let dsid    = %sysfunc(open(_refDset));
        %let nrefvar = %sysfunc(attrn(&dsid, nvars));
        %let rc      = %sysfunc(close(&dsid));


        /******************************************************
        Print source dataset
        ******************************************************/
        
        proc report data  = _refDset nowd
        style(column) = [tagattr='format:@'] 
        ;
            column
            %if &reviewonly = Y %then %do;
                %let bgcolor = &issueDsetHDRbgcolor;
                /* Ken Cao on 2015/03/02 */
                %let bgcolor = colors('headerbg');
                __recID
                ("&odsEscapeChar.S={foreground=white fontweight=bold background=&bgcolor just=l}Issue Dataset: &parentIssueID" 
                    _0_&parentIssueID._:)
            %end;
            %do j = 1 %to &nrefdset;
                %let refdset = %upcase(%scan(&refdsets, &j, " "));
                %if &j < 4 %then %let bgcolor = &&sdsethdrbgcolor&j;
                %else %let bgcolor = &sdsethdrbgcolor3;
                /* Ken Cao on 2015/03/02 */
                %let bgcolor = colors('headerbg');
                /** Ken Cao on 2014/11/18: Add a blank column when COLUMN statement contains only one variable **/
                %if &nrefvar > 1 or &reviewonly = Y %then
                ("&odsEscapeChar.S={foreground=white background=&bgcolor fontweight=bold just=l fontsize=10pt font=fonts('font')}Source Dataset: &refdset" 
                    _&j._&refdset._:);
                %else 
                ("&odsEscapeChar.S={foreground=white background=&bgcolor fontweight=light just=l fontsize=10pt font=fonts('font')}Source Dataset: &refdset"
                    _&j._&refdset._: __dummy__);
            %end;
            ;

            %do j = 1 %to &nflyoverVar;
                %if &&dsetnum&j = 0 %then %let bgcolor = &issueDsetHDRbgcolor;
                %else %if &&dsetnum&j < 4 %then %do;
                    %let cnt = &&&dsetnum&j;
                    %let bgcolor = &&sdsethdrbgcolor&cnt;
                %end;
                %else %let bgcolor = &sdsethdrbgcolor3;
                /* Ken Cao on 2015/03/02 */
                %let bgcolor = colors('headerbg');
                define &&var&j / "&&label&j" style(header)=[flyover="&&flyover&j" background=&bgcolor just=c];
            %end;

            * compute dummy column as a blank column;
            %if &nrefvar = 1 and &reviewonly ^= Y %then %do;
                define __dummy__ / ' ' computed style(header)=[background=white];;

                compute __dummy__ / character length = 1;
                    __dummy__ = ' ';
                endcomp;
            %end;


            %if &nobsRef = 0 %then %do;
                compute before / style = [fontweight=bold fontstyle=italic foreground=red fontsize=10pt font=fonts('font')];
                    line "No Observation";
                endcomp;
            %end;

            compute before _page_ / style=header{
                                                       just = l
                                                 background = colors('skipcolor')
                                                       font = fonts('font')
                                                   fontsize = 10pt
                                                 foreground = colors('titlecolor')
                                                 };
                line "&odsEscapeChar.S={fontweight=bold foreground=colors('titlecolor')}Subject &subject";
                line "Parent Issue ID: &parentIssueID: &issueMSG.&odsescapechar.nReference Source Datasets: &refdsets";
            endcomp;

            compute after _page_ / style=header{
                                                          just = l 
                                                          font = fonts('font')
                                                      fontsize = 10pt
                                                    background = white 
                                                    foreground = blue 
                                                textdecoration = underline 

                                                };
                line "=HYPERLINK(""#'Issue Details'!&parentIssueID"", ""Go back to &parentIssueID in worksheet Issue Details"")";
                line "=HYPERLINK(""#'&subject'!&parentIssueID"", ""Go back to &&parentIssueID in worksheet &subject"")";
            endcomp;
        run;
        
        %let StartRow = %eval(&EndRow + 2 + 2);

    %end;




%mend refSheetL2;
