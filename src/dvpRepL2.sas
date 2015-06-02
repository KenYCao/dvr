/*
    Program Name: dvpRepL2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Author: 2014/04/01

    Generate data validation report layout 2.

    Revision History:

    Ken Cao on 2014/07/03:  Use a centeralized location (folder) for all reports (layout 1 - 3);
*/

%macro dvpRepL2(bysite);
    
    /*
    %local date;
    %local time;
    */

    %local outputFolderName;
    %local outputPath;
    %local nSite;
    %local ALLsites;
    %local i;
    %local site;

    /*
    %local nameprefix;
    %local nameprefix2;
    */

    %local filename;

    /*
    * prefix of data validation report;
    %let nameprefix  = %str(Q2_Data_Validation_Report_&studyid2); 
    %let nameprefix2 = %str(Q2_DVR_&studyid2);
    */

    * create folder for all reports to be generated in single run;
    /*
    %getDateTime;
    %let outputFolderName = &nameprefixFolder._&date.T&time;
    %newFolder(foldername = &outputFolderName, parentdir = &outputdir);
    %let outputPath = %str(&outputdir/&outputFolderName);
    */

    %newFolder(foldername = L2, parentdir = &outputdir);
    %let outputPath = %str(&outputdir/L2);

    * create dataset to collect naming ranges;
    data &namingRangeDset;
        length path $255 filename $255 newpath $255 newFileName $255 sheet $32 rangename $255 startrow startcol endrow endcol 8 comment $255;
        call missing(path, filename, newpath, newFileName, sheet, rangename, startrow, endrow, startcol, endcol, comment);
        if 0;
    run;

    * get # of sites(nSite) and list of all sites(ALLsites) ;
    %getALLsites;

    %do i = 1 %to &nSite;
        %let site = %scan(&ALLsites, &i, @);

        * report all issues;
        %if &reportALL = Y %then %do;
            %dvpRepL2KNL(cat=ALL, outputpath=&outputpath,site=&site);
        %end;

        * report only new issues;
        %if &reportNEW = Y %then %do;
            %dvpRepL2KNL(cat=NEW, outputpath=&outputpath, site=&site);
        %end;

        * report only modified issues;
        %if &reportMODIFIED = Y %then %do;
            %dvpRepL2KNL(cat=MODIFIED, outputpath=&outputpath, site=&site);
        %end;

        * report only repeat issues;
        %if &reportREPEAT = Y %then %do;
            %dvpRepL2KNL(cat=REPEAT, outputpath=&outputpath, site=&site);
        %end;
    %end;


%mend dvpRepL2;

