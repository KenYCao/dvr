/*
    Program Name: readConfig_vbs.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/22

    convert individual worksheet in configuration file to individual csv file.
    read csv file.


    Ken Cao on 2014/05/16: Add a new column "Type for delivery" - New issue type after review
    Ken Cao on 2014/07/03: Add a new worksheet "layout3" for generating layout 3 report.
	Ken Cao on 2015/01/21: Save csv as utf-8 format when DVR is called in UTF-8 environment.
*/

%macro readConfig_vbs(configdir = , configfn=);

    %local callFile;
    %local rc;
    %local filrf;
    %local dlm;
	

	** Ken Cao on 2015/01/21: determine SAS Encoding option;
	%local encoding;
	%let encoding = %upcase(%sysfunc(getoption(encoding)));


    * vbscript filename to call sub expCFG2csv;
    %let callFile = &tempDir\callExpCFG2csv.vbs;

    * delimiter of csv file;
    %*let dlm = %str(",");
	%let dlm = %str('09'x);

    data _null_;
        file "&callFile";
        put 'Dim fsObj : Set fsObj = CreateObject("Scripting.FileSystemObject")';
        put "Dim vbsFile : Set vbsFile = fsObj.OpenTextFile(""&rootdir\src\expCFG2csv.vbs"", 1, False)";
        put 'Dim myFunctionsStr : myFunctionsStr = vbsFile.ReadAll';
        put 'ExecuteGlobal myFunctionsStr';
		%if "&encoding" = "WLATIN1" %then %do;
        put "call expCFG2csv(""&configdir\&configfn"", ""&tempDir"", 20)";
		%end;
		%else %if "&encoding" = "UTF-8" %then %do;
        put "call expCFG2csv(""&configdir\&configfn"", ""&tempDir"", 42)";
		%end;
		%else %do;
			putlog "ERR" "OR: Unsupported encoding! This may lead to unexpected result";
			put "call expCFG2csv(""&configdir\&configfn"", ""&tempDir"", 6)";
		%end;
        put 'vbsFile.Close';
        put 'Set vbsFile = Nothing';
        put 'Set fsObj = Nothing';
    run;

    * convert configuration file (excel spreadsheet) into multiple CSV file;
    x "'&callFile'";

    * worksheet 1: config;
    %let rc = %sysfunc(filename(filrf, &tempDir\config.csv));
    %if &rc ^= 0 %then %do;
        %let isErr = 1;
        %return;
    %end;
    data _config;
        infile &filrf LRECL = 65536 dsd dlm = &dlm missover firstobs = 2 termstr=crlf;
        informat issueid $32. key1 - key&nkeyvcol $300. rep1 - rep&nrepvcol $300.;
        input issueid key1 - key&nkeyvcol rep1 - rep&nrepvcol;
        issueid = upcase(issueid);
        linenum1 + 1; *<!--linenum is used for e r r o r check--!>*;
        linenum = linenum1+1;
        if strip(issueid) ^= ' ';
        drop linenum1;
    run;
    %let rc = %sysfunc(filename(filrf));


    * worksheet 2: issue_list;
    %let rc = %sysfunc(filename(filrf, &tempDir\issue_list.csv));
    %if &rc ^= 0 %then %do;
        %let isErr = 1;
        %return;
    %end;
    data _isslist;
        infile &filrf LRECL = 65536 dsd dlm = &dlm missover firstobs = 2 termstr=crlf;
        informat issueid $32. issueTypR $255. issueTypD $255. sdset $200. msgr $1024. msgd $1024. refdsets $255. refvars $32767.;
        input issueid issueTypR issueTypD sdset msgr msgd refdsets refvars;

        issueid   = upcase(issueid);
        issueTypR = upcase(issueTypR);
        issueTypD = upcase(issueTypD);
        sdset     = strip(sdset);
        refdsets  = upcase(refdsets);
        refvars   = upcase(refvars);

        linenum1 + 1; *<!--linenum is used for e r r o r check-->*;
        linenum = linenum1 + 1;
        if strip(issueid) ^= ' ';
        drop linenum1;
    run;
    %let rc = %sysfunc(filename(filrf));


    * worksheet 3: source datasets;
    %let rc = %sysfunc(filename(filrf, &tempDir\source_dataset.csv));
    %if &rc ^= 0 %then %do;
        %let isErr = 1;
        %return;
    %end;
    data _sourceDsets;
        infile &filrf LRECL = 65536 dsd dlm = &dlm missover firstobs = 2 termstr=crlf;
        informat ssdset $32. ssdsetlbl $255.;
        input ssdset ssdsetlbl;
        ssdset    = upcase(strip(ssdset));
        ssdsetlbl = strip(ssdsetlbl);
    run;
    %let rc = %sysfunc(filename(filrf));


    * worksheet 4: ALL Issue Type;
    %let rc = %sysfunc(filename(filrf, &tempDir\issue_type.csv));
    %if &rc ^= 0 %then %do;
        %let isErr = 1;
        %return;
    %end;
    data _AllissueType0;
        infile &filrf LRECL = 65536 dsd dlm = &dlm missover firstobs = 2 termstr=crlf;
        informat issueTyp $255. alterText $255. hide $1.;
        input issueTyp alterText hide;
        issueTyp  = upcase(issueTyp);
        hide      = upcase(hide);
    run;
    %let rc = %sysfunc(filename(filrf));


    * worksheet 5: For layout 3 report;
    %let rc = %sysfunc(filename(filrf, &tempDir\layout3.csv));
    %if &rc ^= 0 %then %do;
        %let isErr = 1;
        %return;
    %end;
    data _L3config0;
        infile &filrf LRECL = 65536 dsd dlm = &dlm missover firstobs = 2 termstr=crlf;
        informat issueid $32. keyvars $1024. fieldname $1024. __finding $32767.;
        input issueid keyvars fieldname __finding; 
        issueid = upcase(strip(issueid)); 
        keyvars = upcase(strip(keyvars)); 
    run;
    %let rc = %sysfunc(filename(filrf));

    * clear temporary files;
    x "del ""&tempDir\*.csv""";
    x "del ""&tempDir\&callFile""";


%mend readConfig_vbs;
