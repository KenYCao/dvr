/*
    Program Name: dvpRepL2.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Author: 2014/07/03

    Generate data validation report layout 3.
*/

%macro dvpRepL3(bysite);
    
    %local date;
    %local time;
    %local outputFolderName;
    %local outputPath;
    %local nSite;
    %local ALLsites;
    %local i;
    %local site;
    %local filename;

    * create folder for all layout 3 reports;
    %newFolder(foldername = L3, parentdir = &outputdir);
    %let outputPath = %str(&outputdir/L3);

    * get # of sites(nSite) and list of all sites(ALLsites) ;
    %getALLsites;

    %do i = 1 %to &nSite;
        %let site = %scan(&ALLsites, &i, @);

        * report all issues;
        %if &reportALL = Y %then %do;
            %dvpRepL3KNL(cat=ALL, outputpath=&outputpath,site=&site);
        %end;

        * report only new issues;
        %if &reportNEW = Y %then %do;
            %dvpRepL3KNL(cat=NEW, outputpath=&outputpath, site=&site);
        %end;

        * report only modified issues;
        %if &reportMODIFIED = Y %then %do;
            %dvpRepL3KNL(cat=MODIFIED, outputpath=&outputpath, site=&site);
        %end;

        * report only repeat issues;
        %if &reportREPEAT = Y %then %do;
            %dvpRepL3KNL(cat=REPEAT, outputpath=&outputpath, site=&site);
        %end;
    %end;


%mend dvpRepL3;

