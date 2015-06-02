/*
    
    Program Name: newFolder.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/04/08

    ********************************************************************************
    This program belongs to patient profile solutions. Program will create folders
    in output folder for a new study whose name is the same as in plug-in folder. For
    ease of mainteinance, study identifier is recommended for folder name. In case
    of target folder exists, nothing will be done.
    *******************************************************************************

*/

%macro newFolder(foldername=, parentdir=);
    %local rs;

    %let foldername = %sysfunc(strip(&foldername));
    %let parentdir  = %sysfunc(strip(&parentdir));

    *remove trailing slash or back slash;
    %if "%substr(&parentdir,%length(&parentdir))"="/" or "%substr(&parentdir,%length(&parentdir))"="\" %then 
        %let parentdir=%substr(&parentdir,1,%length(&parentdir)-1);

    %if not %sysfunc(exist(&parentdir\&foldername)) %then
    %do;
        %let rs=%sysfunc(dcreate(&foldername,&parentdir\));
    %end;
%mend newFolder;

