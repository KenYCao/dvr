/*
    Program Name: inputExceptionHandle.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/01/16

    REVSION HISTORY:
    Ken Cao on 2014/09/12: Fix a bug when user specified subjects are too long (more than one line).
    Ken Cao on 2015/02/12: Add default value for parameter MDFVARCOLOR
*/



%macro inputExceptionHandle();

    %local  blank;

    %let blank = ;

    /* 
        If those input parameters are null, then default value will be assigend 
        %IsNull(macro-variable-name, macro-variable-value, default-value, suppress-e r r o r -msg).
    */
    %IsNull(rerun,           &rerun,           Y,  Y);
    %IsNull(compare,         &compare,         N,  Y);
    %IsNull(displayvarname,  &displayvarname,  Y,  Y);
    %IsNull(displayvarlabel, &displayvarlabel, Y,  Y);
    %IsNull(testmode,        &testmode,        Y,  Y);

    * default: generate both layout1 and layout2 output, layout2 not by sie;
    %IsNull(layout1,         &layout1,         N,  Y);
    %IsNull(layout2,         &layout2,         N,  Y);
    %IsNull(layout3,         &layout3,         N,  Y);
    %IsNull(bysite,          &bysite,          N,  Y); 


    * default # of key variables and report variable in configuration file;
    %IsNull(nkeyvcol,        &nkeyvcol,       10,  Y); 
    %IsNull(nrepvcol,        &nrepvcol,       20,  Y); 




    * by default output is generated for review purpose only;
    %IsNull(reviewonly,      &reviewonly,     Y,    Y);
    %IsNull(debug,           &debug,          Y,    Y);

    * label is displayed by default.;
    %IsNull(reverseVarNameLBL, &reverseVarNameLBL, N, Y);

    /*displayVarName and displayVarLabel cannot be N at the same time*/
    %if &displayVarName = N and &displayVarLabel = N %then
        %do;
            %let IsErr = 0.5;
            %put WARN&blank.ING: Paramter DISPLAYVARNAME and DISPLAYVARLABEL cannot be N at the same time;
            %put NOTE: Parameter DISPLAYVARNAME is set to Y;
            %let displayVarName = Y;
        %end;


    /*Check if required input parameter is null*/
    %IsNull(rootdir,  &rootdir  );
    %IsNull(sdatadir, &sdatadir );
    %IsNull(configfn, &configfn );
    %IsNull(studyid,  &studyid  );
    %IsNull(runid,    &runid    );

    %if &compare = Y %then
        %do;
            %IsNull(benchmarkid, &benchmarkid);
        %end;
    
    %if &IsErr = 1 %then %return;


    /*
        reportALL; report all issues. Default is Y.
        reportNew: report only new issues. Default is N.
        reportModified: report only modified issues. Default is N.
        reportRepeat: report only repeated issues. Default is N.
    */

    %IsNull(reportALL,      &reportALL,      Y, Y);
    %IsNull(reportNew,      &reportNew,      N, Y);
    %IsNull(reportModified, &reportModified, N, Y);
    %IsNull(reportRepeat,   &reportRepeat,   N, Y);

    /*
        Enable user to customized colors.
    */
    %IsNull(skipColor,   &skipColor,   #DBEEF3, Y);
    %IsNull(breakColor,  &breakColor,  #FDF3D9, Y);
    %IsNull(newcolor,    &newcolor,    pink,    Y);
    %IsNull(mdfcolor,    &mdfcolor,    #FFF2CC, Y);
    %IsNull(mdfvarcolor, &mdfvarcolor, #C1C1C1, Y);

    %IsNull(issueDsetHDRbgcolor, &issueDsetHDRbgcolor,  #BDD7EE);
    %IsNull(sdsethdrbgcolor1,    &sdsethdrbgcolor1,     #FFF2CC);
    %IsNull(sdsethdrbgcolor2,    &sdsethdrbgcolor2,     #D9E1F2);
    %IsNull(sdsethdrbgcolor3,    &sdsethdrbgcolor3,     #E2EFDA);

    %IsNull(namePrefixFileName, &namePrefixFileName, Q2_Data_Validation_Report_&studyid2); /* prefix for output filename */
    %IsNull(nameprefixFolder,   &nameprefixFolder,   Q2_DVR_&studyid2); /* prefix for output folder */
 
    %IsNull(splitchar,   &splitchar,   #); /* prefix for output folder */

    %IsNull(showALLissueIDinIssueSum, &showALLissueIDinIssueSum,  N);
    
    %IsNull(useColorCode, &useColorCode,  Y, Y);
    %IsNull(updatepdata,  &updatepdata,   N, Y);


    %IsYN(rerun,              &rerun             );
    %IsYN(compare,            &compare           );
    %IsYN(displayvarname,     &displayvarname    );
    %IsYN(displayvarlabel,    &displayvarlabel   );
    %IsYN(skipDataProcessing, &skipDataProcessing);
    %IsYN(testmode,           &testmode          );
    %IsYN(layout1,            &layout1           );
    %IsYN(layout2,            &layout2           );
    %IsYN(layout3,            &layout3           );
    %IsYN(bySite,             &bysite            );
    %IsYN(reviewOnly,         &reviewOnly        );
    %IsYN(debug,              &debug             );
    %IsYN(reverseVarNameLBL,  &reverseVarNameLBL );
    %IsYN(reportALL,          &reportALL         );
    %IsYN(reportNew,          &reportNew         );
    %IsYN(reportModified,     &reportModified    );
    %IsYN(reportRepeat,       &reportRepeat      );
    %IsYN(useColorCode,       &useColorCode      );


    %IsYN(showALLissueIDinIssueSum, &showALLissueIDinIssueSum);


    * if compare is set to N then reportALL/reportNew/reportModified/reportRepeat ;
    %if &compare = N %then 
        %do;
            %if &reportALL = N 
                or &reportNew = Y 
                or &reportModified = Y 
                or &reportRepeat = Y  
            %then %put WARN&blank.ING: Parameter COMPARE is set to N. REPORTALL will be set to Y. 
                        REPORTMODFIED/REPORTNEW/REPORTREPEAT will be set to N.;

            %let reportALL = Y;
            %let reportNew = N;
            %let reportModified = N;
            %let reportRepeat = N;
        %end;


    /*
    %chkDir(&rootdir             );
    %chkDir(&sdatadir            );
    %chkDir(&configdir\&configfn );
    %chkDir(&pgmdir\&updateFile  );
    %chkDir(&debugdir            );
    %chkDir(&tempDir             );
    */


    * Check validty of user specified colors;
    %chkColor(skiColor,            &skipColor,            #DBEEF3);
    %chkColor(breakColor,          &breakColor,           #FDF3D9);
    %chkColor(newColor,            &newcolor,             pink   );
    %chkColor(mdfColor,            &mdfcolor,             #FFF2CC);
    %chkColor(issueDsetHDRbgcolor, &issueDsetHDRbgcolor,  #BDD7EE);
    %chkColor(sdsethdrbgcolor1,    &sdsethdrbgcolor1,     #FFF2CC);
    %chkColor(sdsethdrbgcolor2,    &sdsethdrbgcolor2,     #D9E1F2);
    %chkColor(sdsethdrbgcolor3,    &sdsethdrbgcolor3,     #E2EFDA);


    

    * list of sites to be ran against;
    %let sites = %upcase(&sites);

    * list of subjects to be ran against;
    %let subjects = %upcase(&subjects);

    /* 
        remove line feed (which will be treated as blank by SAS).
    */
    %macro removeLF(mvar, mval); 
    data _null_;
        length val $32767;
        val = "&mval";
        /* Ken Cao on 2014/09/12: use '\s*@\s*' as the target string (remove any space(\s) left/right behind the @ */
        val = prxchange('s/\s*@\s*/@/', -1, val);
        call symput("&mvar", strip(val));
    run;
    %mend removeLF;

    %removeLF(sites, &sites);
    %removeLF(subjects, &subjects);

    /*
    * IsAccessAvailable;
    %if %length(&IsAccessAvailable) > 0 and not (&IsAccessAvailable = 0 or &IsAccessAvailable = 1) %then
        %do;
            %put WARN&blank.ING: Invalid value of IsAccessAvailable;
            %let IsAccessAvailable =;
        %end;
    */

    %if &layout2 = Y %then
        %do;
            %if %length(&subjectvar) = 0 %then 
                %do;
                    %let IsErr = 1;
                    %put ERR&blank.OR: Please assign variable name of SUBJECT IDENTIFIER;
                %end;
            %if &bysite = Y and %length(&sitevar) = 0 %then
                %do;
                    %let IsErr = 1;
                    %put ERR&blank.OR: Please assign variable name of SITE;
                %end;
        %end;

%mend inputExceptionHandle;
