/*
    Program Name: legend.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/10

    Generate legend for color code of data comparison

    Modification History
    
    Ken Cao on 2015/01/27: Fixed a typo.

*/


%macro legend(noprint, showColorCodeLegend);

    %local nobs;
    
    %let lastTitleLine = 0;

    %let noprint = %upcase(&noprint);

    %if %length(&showColorCodeLegend) = 0 %then %do;
        %if &compare = Y %then %let showColorCodeLegend = Y;
        %else %let showColorCodeLegend = N;
    %end;

    data __legend;
        length var $256 ord $1;
        var = ' ';
        ord = '0';
        output;
        %if &showColorCodeLegend = Y %then %do;
        var = "New Issue"; 
        ord = '1';
        output;
        var = "The record was modified in new data transfer"; 
        ord = '2';
        output;
        var = 'Repeat Issue';
        ord = '3';
        output;
        %end;
    run;

    %getDsetInfo(indata = __legend, getNOBS = Y);
    %let lastTitleLine = &nobs;

    %if &noprint = NOPRINT %then %return;

    proc report data = __legend nowd noheader;
        column blankcol var ord;
        define blankcol / '' computed style(column)=[foreground=white] %if &reviewonly = Y %then noprint;;
        define var / display style(column) = [fontweight=bold tagattr = "mergeAcross:yes" ];
        define ord / noprint;

        compute ord;
            if ord = '1' then call define (_row_, 'style', "style=[background=&newcolor fontsize=10pt font=fonts('font') foreground=colors('titlecolor')]");
            if ord = '2' then call define (_row_, 'style', "style=[background=&mdfcolor fontsize=10pt font=fonts('font') foreground=colors('titlecolor')]");
            if ord = '3' then call define (_row_, 'style', "style=[background=white fontsize=10pt font=fonts('font') foreground=colors('titlecolor')]");
        endcomp;
        compute blankcol;
            blankcol = .;
        endcomp;
    run;

%mend legend;
