/*
    Program Name: dvpReportBYSubject.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/28

    Kernal program for dvp report layout 2.

*/

%macro dvpReportBYSubject(site);

    
    * Dataset Summary Sheet;
    %subjectSummary(&site);


    * Dataset Summary Sheet;
    %dsetSummary(&site);


    * Issue Summary Sheet;
    %issueSummary_Layout2(&site);


    * Issue Detail Sheet;
    %issueDetails(&site);


    * Deleted issues;
    %if &reviewonly = Y %then %do;
    %DeletedIssues(&site);
    %end;


    * Individual Subject Sheet.;
    %printALLSubjects(&site);

    ods tagsets.excelxp close;


%mend dvpReportBYSubject;
