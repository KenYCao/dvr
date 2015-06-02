/*
    Program Name: setupSASEnvir.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Date: 2013/10/16

    setup SAS runtime environment for DVP.

    REVISION HISTORY:
    2014/03/27 Ken Cao: Add a debug folder under root directory.
    2015/02/29 Ken Cao: Add ods path option.
*/


filename src "&rootdir\src";
option mautosource sasautos = (sasautos src) ;   /*autocomplie all macros*/  
ods path work.templat(update) sashelp.tmplmst(read); 
%include "&rootdir\src\functions.sas";
%include "&rootdir\src\style.sas"; ** load style template;
options cmplib=work.func; /* load customized functions*/

%macro setupSASEnvir(restrict);

    %local blank;


    %GlbMvars;

    %IsNull(studyid2, &studyid2, &studyid, Y);

    %if %sysfunc(prxmatch(/[''""|:<>*\/\\]/, &studyid2)) %then
        %do;
            %let IsErr = 1;
            %put ERR&blank.OR: In case of study identfier contains characters ''""\/?:<>*|, please assign
                 another value that does not contains those characters to parameter STUDYID2; Please make
                 sure study folder under &rootdir\project are exactly same as value of parameter STUDYID2.;
            %return;
        %end;


    *ods escape character;
    ods escapechar = "&odsEscapeChar";

    *setup standard folders;
    %if %length(&outputdir)  = 0  %then %let outputdir  = %str(&rootdir\report\&studyid2);
    %if %length(&pdatadir)   = 0  %then %let pdatadir   = %str(&rootdir\report\&studyid2\processed data);
    %if %length(&pdatadirbk) = 0  %then %let pdatadirbk = %str(&rootdir\report\&studyid2\processed data\backup);
    %if %length(&projectDir) = 0  %then %let projectDir = %str(&rootdir\project\&studyid2);
    %if %length(&configdir)  = 0  %then %let configdir  = %str(&rootdir\project\&studyid2);
    %if %length(&macrodir)   = 0  %then %let macrodir   = %str(&rootdir\src);
    %if %length(&pgmdir)     = 0  %then %let pgmdir     = %str(&rootdir\project\&studyid2);
    %if %length(&tempDir)    = 0  %then %let tempDir    = %str(&rootdir\temp\&studyid2);
    %if %length(&debugdir)   = 0  %then %let debugdir   = %str(&tempDir\debug);
    %if %length(&tempbkdir)  = 0  %then %let tempbkdir  = %str(&tempDir\tempbk);


    *system will ignore user specification of outputdir/pdatadir/pdatadirbk if in restricted mode (1);
    %if %length(&restrict)   = 0  %then %let restrict   = 1;

    %if &restrict = 1 %then /*use standard directory*/
        %do;
            %let outputdir  = %str(&rootdir\report\&studyid2);
            %let pdatadir   = %str(&rootdir\report\&studyid2\processed data);
            %let pdatadirbk = %str(&rootdir\report\&studyid2\processed data\backup);
            %let projectDir = %str(&rootdir\project\&studyid2);
            %let configdir  = %str(&rootdir\project\&studyid2);
            %let macrodir   = %str(&rootdir\src);
            %let pgmdir     = %str(&rootdir\project\&studyid2);
            %let debugdir   = %str(&tempDir\debug);
            %let tempbkdir  = %str(&tempDir\tempbk);
        %end;


    %inputExceptionHandle;
    %if &IsErr = 1 %then %return;


    *library for source datasets;
    libname source "&sdatadir";
    option nofmterr fmtsearch = (source work);




    %chkDir(&outputdir, Y);
    %if &IsErr = 1 %then 
        %do;
            %put WARN&blank.ING: Directory(OUTPUTDIR): &outputdir not exists.;
            %let IsErr = 0;
            %let outputdir  = %str(&rootdir\report\&studyid2);
            %put WARN&blank.ING: Directory &outputdir will be used as OUTPUTDIR instead.;
            %newFolder
            (
                foldername = &studyid2, 
                parentdir  = &rootdir\report
            );  
            %let IsErr = 0;
        %end;

    %chkDir(&pdatadir, Y);
    %if &IsErr = 1 %then 
        %do;
            %let IsErr = 0;
            %put WARN&blank.ING: Directory(PDATADIR): &pdatadir not exists.;
            %let pdatadir   = %str(&rootdir\report\&studyid2\processed data);
            %put WARN&blank.ING: Directory &pdatadir will be used as PDATADIR instead.;
            %newFolder
            (
                foldername = processed data,
                parentdir  = &rootdir\report\&studyid2
            );
            %let IsErr = 0;
        %end;
    
    %chkDir(&pdatadirbk, Y);
    %if &IsErr = 1 %then 
        %do;
            %let IsErr = 0;
            %put WARN&blank.ING: Directory(PDATADIRBK): &pdatadirbk not exists.;
            %let pdatadirbk = %str(&rootdir\report\&studyid2\processed data\backup);
            %put WARN&blank.ING: Directory &pdatadirbk will be used as PDATADIRBK instead.;
            %newFolder
            (
                foldername=backup,
                parentdir=&rootdir\report\&studyid2\processed data
            );
            %let IsErr = 0;
        %end;


    %chkDir(&tempDir, Y);
    %if &IsErr = 1 %then 
        %do;
            %let IsErr = 0;
            %put WARN&blank.ING: Directory(TEMPDIR): &tempDIR not exists.;
            %let tempDir   = %str(&rootdir\temp\&studyid2);
            %put WARN&blank.ING: Directory &tempDir will be used as TEMPDIR instead;
            %newFolder
            (
                foldername=&studyid2,
                parentdir=&rootdir\temp
            );
            %let IsErr = 0;
        %end;

    * Ken on 2014/05/15: Make two directory in temporary directory. One for debug and the other for temporary backup;
    %newFolder
    (
        foldername=tempbk,
        parentdir=&tempDir
    );

    %let tempbkdir = &tempDir\tempbk;

    %newFolder
    (
        foldername=debug,
        parentdir=&tempDir
    );

    %let debugdir = &tempDir\debug;
 
    libname out            "&pdatadir"; /*duplicate library reference because of historic reason*/
    libname &pdatalibrf    "&pdatadir";
    libname &pdatabklibrf  "&pdatadirbk";
    libname &debuglibrf    "&debugdir";
    libname &tempbklibrf   "&tempbkdir";

%mend setupSASEnvir;
