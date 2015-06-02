/*
    Program Name: dvp.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/01/15

        
    Revision History:

    Ken Cao on 2014/07/03: Use a centeralized location (folder) for all reports (layout 1 - 3);
    Ken Cao on 2014/12/22: Set line size to maxinum size (256).
*/


option mprint mlogic validvarname=upcase noxwait xsync noquotelenmax fullstimer compress=yes ls=256;

%macro dvr(project);

    %local blank;
    %local reGenerateData;
    %local whichProject; 
    %local rc;
    %local date;
    %local time;
    

    %let blank = ;


    %include 'src\selectProject.sas';
    %include 'src\GlbMvars.sas';


    * Setup Global macro variable;
    %GlbMvars;

    %if %length(&project) = 0 %then %do;
        * SAS Windowing Environment to let user enter project name;
        %selectProject;
    %end;
    %else %do;
        %let whichProject = &project;
        %let rc = %sysfunc(fileexist(project/&whichProject/_setup.sas));
        %if &rc = 0 %then %do;
            %let isErr = 1;
            %put ERR&blank.OR: In&blank.valid project name: &whichproject;
        %end;
    %end;

    %if IsErr = 1 %then %goto EXIT;


    * load project setup file;
    %include "project/&whichProject/_setup.sas";

    %if IsErr = 1 %then %goto EXIT;

    ***********************************************************************************************;
    * generate issue datasets;
    * if &skipDataProcessing is set to Y, then program will skip data processing part ;
    * and generate report using existing data;
    ***********************************************************************************************;

    * whether to regenerate issue datasets;
    * force to not regenerate issue datasets when &reviewonly is set to N (for security concern).;

    %if &skipDataProcessing = Y %then %let reGenerateData = N;
    %else %let reGenerateData = Y;
    %if &reviewonly = N %then %let reGenerateData = N;

    %if &reGenerateData = Y %then %do;
        ** Ken Cao on 2015/03/19: Generally this backup takes too long time;
        /*
        proc datasets lib = &tempbklibrf kill nolist nodetails nowarn;
        quit;
        */

        * Initialization of data directory and data backup directory;
        %sasLibInit;

        * Run all data validation programs;
        x "cd /d ""&pgmdir"" & ""&pgmdir\Run_all.bat""";
        * return to root direcotry;
        x "cd /d ""&rootdir""";

         * all new fields;
         %alterPDATA;
    %end;
    %if IsErr = 1 %then %goto EXIT;
    


    
    ***********************************************************************************************;
    * Import configuration file;
    ***********************************************************************************************;
    %importConfig(&configdir, &configfn);
    %if &IsErr = 1 %then %goto EXIT;




    ***********************************************************************************************;
    * generate record ID;
    ***********************************************************************************************;
    %if &reGenerateData = Y %then %do;
        %GenRecordID(Y);
    %end;
    %if IsErr = 1 %then %goto EXIT;





    ***********************************************************************************************;
    * Compare issue datasets with its backup;
    ***********************************************************************************************;

    %if &compare = Y and &reGenerateData = Y %then %do;
        %dvpCompare
        (
            pdata   = &pdatalibrf,
            pdatabk = &pdatabklibrf
        );
        %end;



    ***********************************************************************************************;
    * update PDATA
    ***********************************************************************************************;
    %updatePDATA(&updateFile);

    %if IsErr = 1 %then %goto EXIT;



    ***********************************************************************************************;
    * export all record ID for reviewonly run;
    ***********************************************************************************************;
    %exportRecordID;



    ***********************************************************************************************;
    * check duplicate key / record id;
    ***********************************************************************************************;
    %CHKdupID(N); /* Y/N: suppress w a r n i n g message for duplicate key/record ID */

    %if &layout2 = Y %then
        %do;
            %chkSubjectVar(&subjectvar);
            %if &bySite = Y %then 
                %do;
                    %chkSiteVar(&sitevar);
                %end;
        %end; 


    %if IsErr = 1 %then %goto EXIT;



    ***********************************************************************************************;
    * update NOBS in configuration dataset;
    ***********************************************************************************************;
    %updateNOBS(&dvpConfigDset);




    ***********************************************************************************************;
    * Generate summarize datasets
    ***********************************************************************************************;

    %dvpSummary
    (
        byIssue      = Y,        
        bySourceDset = Y,        
        bySite       = &bysite,  
        bySubject    = %if &layout2 = Y or &layout3 = Y %then Y; %else N;
    );




    ***********************************************************************************************;
    *  Create folder for report.
    ***********************************************************************************************;
    %if &layout1 = Y or &layout2 = Y or &layout3 = Y %then %do;
        %getDateTime;
        %let outputFolderName = &nameprefixFolder._&date.T&time;
        %newFolder(foldername = &outputFolderName, parentdir = &outputdir);
        %let outputdir = %str(&outputdir/&outputFolderName);
    %end;




    ***********************************************************************************************;
    *  Layout 1 output: Normalized 
    ***********************************************************************************************;

    %if &layout1 = Y %then
        %do;
            %dvpNormalize; /* output: _dvpAllIssueNM*/
            %dvpRepL1;
        %end;



    ***********************************************************************************************;
    *  Layout 2 output: plain structure (by subjects / sites)
    ***********************************************************************************************;

    %if &layout2 = Y %then
        %do;
            %dvpRepL2(&bySite);
        %end;


    ***********************************************************************************************;
    *  Layout 3 output: 
    ***********************************************************************************************;

    %if &layout3 = Y %then
        %do;
            %dvpRepL3(&bySite);
        %end;


%EXIT:
    %if &debug = Y %then 
        %do;
            option replace;
            proc datasets lib = &debuglibrf kill nolist; quit;
            proc copy in = work out = &debuglibrf memtype = data; run;
        %end;
    x "cd /d ""&tempDir"" & del *.xml";
    x "cd /d ""&tempDir"" & del *.vbs";

%mend dvr;

%dvr(&sysparm);
