/*
    Program Name: setupODS.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/02      
*/

/***********************************************************
cat: issue category (all issues/new/modified/repeat)
outputpath: directory of output
nameprefix: name prfix + study identifier
************************************************************/


%macro setupODS(cat=, outputpath=, site=);

    %local date;
    %local time;
    %local filename;

    %let cat = %upcase(&cat);


    %getDateTime;
    %let filename = &nameprefixFileName._%upcase(&cat)_&date.T&time;

    %if &bySite = Y %then %do;
        %if &compare = Y %then %do;
            %newFolder(foldername = &cat, parentdir = &outputpath);
            %let outputpath = %str(&outputpath\&cat);
        %end;
        %let filename = %str(&nameprefixFileName._SITE_&site._%upcase(&cat)_&date.T&time);
    %end;

    * clear naming range dataset;
    proc sql;
        delete from &namingRangeDset;
        insert into &namingRangeDset (path, filename, newpath, newfilename)
        values ("&tempDir", "&filename..xml", "&outputpath", "&filename..xlsx");
    quit;


    ods _all_ close;


    * create new tagsets.excelxp output;
    * Ken on 2014/04/15: create a report in temprary directory first;
    ods tagsets.excelxp /*path = "&outputpath"*/ path = "&tempDir"  file = "&filename..xml"  style = dvrstyle
    options(
        orientation='landscape'
        autofit_height="yes"
        wraptext="yes"
        fittopage="yes"
        gridlines="no"
        embedded_titles='yes'
        embedded_footnotes='yes'
        frozen_headers='yes'
    );

    

%mend setupODS;
