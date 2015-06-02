/*
    Program Name: subjectIndex.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/13

    Print index table for a subject

*/


%macro subjectIndex(site=, subject=, indexStartRow=, cat = );

    %local returncol;
    %local returnrow;


    %let returncol = 1;

    %let cat = %upcase(&cat);


    *************************************************************;
    * get line number of the subject in subject summary sheet.
    *************************************************************;
    
    %getReturnRowSubj(&subject);



    *************************************************************;
    * print index table for the subject
    *************************************************************;

    data __IDXsubj0;
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
    run;

    proc sort data  = __IDXsubj0; by issueid; run;

    data __IDXsubj;
        set __IDXsubj0 nobs=_nobs_;
        nobs2 = lag(nobs);
        retain  _issueheadernum _1stissuestartnum;
        if _n_ = 1 then
            do;
                /* index table start line number */
                _indexstartnum     = &indexStartRow;
                _indexheaddernum   = 2; /* # of lines of index header number */
                _indexendnum       = _indexstartnum + _nobs_ + _indexheaddernum - 1;  /* index table end line number */
                _1stissuestartnum  = _indexendnum + 2; /* first issue start number */
                _issueheadernum    = 3; /* number of lines of issue dataset header */
            end;
        retain _issuestartnum;
        if _n_ = 1 then _issuestartnum = _1stissuestartnum;
        else _issuestartnum = _issuestartnum + _issueheadernum + nobs2 + 2;
        _issueendnum = _issuestartnum + _issueheadernum + nobs - 1;

        length _range $40 hplink $256;
        _range = "R"||strip(put(_issuestartnum, best.))||"C1"||':R'||strip(put(_issueendnum, best.))||"C1";
        
        hplink = "=HYPERLINK("""||"#'"||strip(subject)||"'!"||strip(_range)||""", """||strip(issueid)||""")";

    run;




    * Ken on 2014/04/14: Use range name in hyperlink function;
    data __IDXsubj;
        set __IDXsubj0;
        hplink = "=HYPERLINK("""||"#'"||strip(subject)||"'!"||strip(issueid)||""", """||strip(issueid)||""")";
    run;

    proc sort data = __IDXsubj; by issuetypn issueid; run;

    proc report data = __IDXsubj nowd spanrows;
        column blankcol issuetypn issuetyp hplink nobs %if &compare=Y %then  nobsnew nobsmdf nobsrpt;;


        define blankcol / '' computed style(column)=[foreground=white] %if &reviewonly = Y %then noprint;;
        define issuetypn / noprint group;
        define issuetyp / 'Issue Type' group style(column)=header{vjust=m fontweight=light foreground=white fontsize=10pt font=fonts('font')};
        define hplink / 'Issue ID' style(column) = [foreground=blue textdecoration=underline fontsize=10pt font=fonts('font')];
        %if &compare = N %then %do;
        define nobs / '# of records';
        %end;
        %else %do;
        define nobs / '# of Issues';
        define nobsnew / 'New';
        define nobsmdf / 'Modified';
        define nobsrpt / 'Repeat';
        %if &cat = ALL %then %do;
        %end;
        %else %if &cat = NEW %then %do;
        define nobs/noprint;
        define nobsmdf / noprint;
        define nobsrpt / noprint;
        %end;
        %else %if &cat = MODIFIED %then %do;
        define nobs / noprint;
        define nobsnew / noprint;
        define nobsrpt / noprint;
        %end;
        %else %if &cat = REPEAT %then %do;
        define nobs / noprint;
        define nobsnew / noprint;
        define nobsmdf / noprint;
        %end;
        %end;

        compute blankcol / char length = 1;
            blankcol =  ' ';
        endcomp;

        compute before _page_ / style=header{just=l foreground=blue background=white fontsize=10pt 
                                             font=fonts('font') textdecoration=underline};
            line "=HYPERLINK(""#'Subject Summary'!R&returnrow.C&returncol"", ""Go Back to Subject Summary Table"")";
        endcomp;

    run;


%mend subjectIndex;
