/*
    Program Name: XLdefineNamedRange.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/11
*/

%macro XLdefineNamedRange(indata);
    
    option noxwait xsync;

    %local xmlReportFileName;
    %local internalFileName;
    %local vbsScriptFilename;

    %let vbsScriptFilename = &tempDir/_defineNamedRange.vbs;

    data _null_;
        file "&vbsScriptFilename";
        put '''On Err' 'or Resume Next';
        put 'Dim objExcel, objWorkbook';
        put 'Set objExcel = CreateObject("Excel.Application")';
        put 'objExcel.Visible = FALSE';
        put 'objExcel.DisplayAlerts = FALSE';
    run;


    * create a temporary vbs script;
    data _null_;
        set &indata end = _eof_;
        length _fullpath $1024;
        file "&vbsScriptFilename" mod;
        
        if _n_ = 1 then do;
            /*
            put '''On Err' 'or Resume Next';
            put 'Dim objExcel, objWorkbook';
            put 'Set objExcel = CreateObject("Excel.Application")';
            put 'objExcel.Visible = FALSE';
            put 'objExcel.DisplayAlerts = FALSE';
            */
            _fullpath = strip(path)||'\'||strip(filename);
            len = length(_fullpath);
            put 'Set objWorkbook = objExcel.Workbooks.Open("' _fullpath $varying1024. len '")';
            call symput('xmlReportFileName', strip(_fullpath));
        end;

        length _startcol _endcol $32 _range $255 _fullrangenm $255 _filenm $255 comment $255;

        if sheet > ' ' then do;
            %XLnum2alpha(num=startcol, alpha=_startcol);
            %XLnum2alpha(num=endcol, alpha=_endcol);

            _range = strip(_startcol)||strip(put(startrow, best.))||':'||strip(_endcol)||strip(put(endrow, best.));

            _fullrangenm = "'"||strip(sheet)||"'!"||strip(rangename);
            len0 = length(sheet);
            len1 = length(_range);
            len2 = length(_fullrangenm);

            put 'objWorkbook.WorkSheets("' sheet $varying255. len0 '").range("' _range $varying255. len1 '").name="'
                _fullrangenm $varying255. len2 '"'; 
            put 'objWorkbook.Names("' _fullrangenm $varying255. len2 '").Comment="' comment '"';
        end;

        if _eof_ then do;
            len0 = length(path);
            _filenm = substr(filename, 1, length(filename) - 4);
            len1 = length(_filenm);
            put 'objExcel.ActiveWorkbook.Save';
            put 'objExcel.ActiveWorkbook.SaveAs"' path $varying1024. len0 '\internal.xls", 56';
            put 'objExcel.ActiveWorkbook.Close';
            _fullpath = strip(path)||'\internal.xls';
            len = length(_fullpath);
            put 'Set objWorkbook = objExcel.Workbooks.Open("' _fullpath $varying1024. len '")';
            len0 = length(newpath);
            len1 = length(newFileName);
            put 'objExcel.ActiveWorkbook.SaveAs"' newpath $varying1024. len0 '\' newFileName $varying1024. len1  '", 51';
            put 'objExcel.ActiveWorkbook.Close';
            put 'Set objWorkbook = Nothing'; /* release memory */
            /*
            put 'objExcel.Quit';
            put 'Set objExcel = Nothing'; 
            */
            call symput('internalFileName', strip(path)||'\internal.xls');
        end;
    run;

    data _null_;
        file "&vbsScriptFilename" mod;
        put 'objExcel.Quit';
        put 'Set objExcel = Nothing'; 
    run;



    x  "'&vbsScriptFilename'"; * execute vb script *;
	/*
    x  "del ""&xmlReportFileName"""; * delete xml file *;
    x  "del ""&internalFileName"""; * delete xml file *;
    */

%mend XLdefineNamedRange;
