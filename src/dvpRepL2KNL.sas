/*
    Program Name: dvpRepL2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Author: 2014/04/01

    Generate data validation report layout 2.
*/


%macro dvpRepL2KNL(cat=, outputpath=, site=);
    
    %local nIssue;
    %local noData;
    %local nobs;


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
        call symput('nIssue', strip(put(_n_, best.)));
    run;

    %if &nIssue = 0 %then %let noData = Y;

    * Ken on 2014/05/13: If no issue generated, then generate a report with summary sheets.;
/*    %if &nIssue = 0 %then %return;*/



    * setup ods tagsets.excelxp;
    %setupODS(cat=&cat, outputpath=&outputpath, site=&site);


    * Dataset Summary Sheet;
    %subjSumL2(&site, &cat);


    * Dataset Summary Sheet;
    %dsetSumL2(&site, &cat);

    * Issue Summary Sheet;
    %issueSumL2(&site, &cat);


    * Issue Detail Sheet;
    %issueDetailsL2(&site, &cat);


    * Reference sheet;
    %refSheetL2(&site, &cat);


    * Deleted issues;
    %if &reviewonly = Y %then %do;
    %DeletedIssues(&site, &cat);
    %end;


    * print individual subjects in the site;
    %printSite(&site, &cat);


    ods tagsets.excelXP close;

    * create naming range;

    /*
    %getDsetInfo(indata=&namingRangeDset, getNOBS=Y);
    %put &nobs;
    */

    data _range;
        set &namingRangeDset end=__end;
        length path2 filename2 newpath2 newfilename2 $255 ;
        retain path2 filename2 newpath2 newfilename2;
        if _n_ = 1 then do;
            path2 = path;
            filename2 = filename;
            newpath2 = newpath;
            newfilename2 = newfilename;
        end;
        path = path2;
        filename = filename2;
        newpath = newpath2;
        newfilename = newfilename2;
        if _n_ = 1 and not __end then delete;        
        drop path2 filename2;
    run;

    %XLdefineNamedRange(_range);
    

%mend dvpRepL2KNL;
