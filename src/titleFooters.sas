/*
    Program Name: titleFooters.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/09
*/


%macro titleFooters(bysite, site);

    %local ssites;
    %local ssubjects;
    %local nsite;
    %local nsubj;
    %local site;
    %local subj;
    %local i;

    %let lastTitleLine = 0;


    /* customized title statement below */
    title; footnote;
    title1 "Q2 Data Validation Report";
    title2 "Generated: &date.T&time.";
    title3 "RUN ID: &runid";


    %if &compare=Y %then %do;
    title4 "Benchmark ID: &benchmarkid";;
    %end;

    %if &bysite = Y %then %do;
    title5 "SITE: &site";
    %end;

    

    * automatically calculate # of title lines;
    data _null_;
        set sashelp.vtitle;
        where type = 'T';
        call symput('lastTitleLine', strip(put(_n_, best.)));
    run;





    * Footers;

    %if &reviewonly = Y %then %do;
        footnote1 "For internal review ONLY! Please DO NOT deliver this report.";
    %end;

    %if &bySite=Y and %length(&sites)>0 %then %do;
        %let ssites = %scan(&sites, 1, @);
        %let nsite = %eval(%sysfunc(countc(&sites, @)) + 1);
        %do i = 2 %to &nsite;
            %let ssites = &ssites, %scan(&sites, &i, @);
        %end;
        footnote2  "Selected Sites: &ssites";
    %end;
    %if %length(&subjects) > 0 %then %do;
        %let ssubjects = %scan(&subjects, 1, @);
        %let nsubject = %eval(%sysfunc(countc(&subjects, @)) + 1);
        %do i = 2 %to &nsubject;
            %let ssubjects = &ssubjects, %scan(&subjects, &i, @);
        %end;
        footnote3 "Selected Subjects: &ssubjects";
    %end;
    
    footnote4 "Source Dataset Directory: &sdatadir";
    footnote5 "COMPARE: &compare. RERUN: &rerun. BYSITE: &bySite";


%mend titleFooters;
