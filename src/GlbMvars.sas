/*
    Program Name: setupSASEnvir.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Date: 2013/10/06
    
    Check if all input paramter are defined in _setup.sas. If not, created one. This macro should be updated
    if new parameter(s) added.
*/


/************************************************************************************************************************************
-- Revision History --

Ken on 2014/02/05: Add 3 parameters: 
    1. layout1: Generate layout1 output (normalized structure)
    2. layout2: Generate layout2 output (non-normalized, by subject/site-subject).
    3. bysite: valid only when layout2=Y. If bysite=Y, then generate output by site. (all outputs will be put under a folder).

2014/03/25 Ken Cao: Add IsAccessAvailable.
2014/03/26 Ken Cao: Add revserVarNameLBL.
2014/03/27 Ken Cao: Add two paramters: hideModified/hideOLD to control whether to hide modified/repeat issue.
2014/03/28 Ken Cao: Delete hideModified/hideOLD. Add parameters: reportALL/reportNew/reportModfied/reportRepeat.
2014/03/28 Ken Cao: Use macro variable as tokens for summary datasets geneated by dvpSummary.
2014/03/28 Ken Cao: Add macro variable sites for user to specify individual sites to run against.
2014/05/12 Ken Cao: Add macro variable subjects to enable user to generate report on specific subject(s).
2015/02/12 Ken Cao: Add macro variale MDFVARCOLOR (colro to highlight changed value).

************************************************************************************************************************************/;


%macro GlbMvars();

    %local glbmvarList1;
    %local glbmvarList2;
    %local glbmvarList;
    %local nglbmvar;
    %local i;

    * only used as reference.;
    %let glbmvarList1 = %str
    (
        pdatalibrf pdatabklibrf sourceLibrf debuglibrf tempbklibrf

        blank isErr allsiteTXT allIssueTXT allDsetTXT allSubjectTXT  

        dvpconfigdset dvpRefConfigDset dvpSDsetConfigDset dvpALLissueTypeDset dsetSummaryDset issueSummaryDset 
        subjectSummaryDset subjectIssueSummaryDset siteSummaryDset deletedIssueDset _siteSubjSumDset _siteDsetSumDset 
        _siteIssueSumDset QstatSummaryDset namingRangeDset updateTBL NOBStbl MD5TBL

        dlm4refdset dlm4refvar dlm4sdset

    );


    * can be customizable;
    %let glbmvarList2 = %str
    (
        rootdir sdatadir outputdir pdatadir pdatadirbk pgmdir macrodir configdir projectDir tempDir debugdir tempbkdir
        configfn updateFile 

        globalvars subjectvar sitevar

        rerun compare displayvarname displayvarlabel testmode skipDataProcessing layout1 layout2 layout3 bysite debug 
        IsAccessAvailable reverseVarNameLBL  reportALL reportNew reportModified reportRepeat reviewonly
        showALLissueIDinIssueSum useColorCode updatepdata

        studyid studyid2 benchmarkid runid sites subjects allIssueType
        nkeyvcol nrepvcol   


        skipColor breakcolor newcolor mdfcolor mdfvarcolor issueDsetHDRbgcolor 
        sdsethdrbgcolor1 sdsethdrbgcolor2 sdsethdrbgcolor3  

        namePrefixFileName nameprefixFolder 

        odsEscapeChar splitchar 
    ); 

    * combined;
    %let glbmvarList = &glbmvarList1 &glbmvarList2;



    %let glbmvarlist = %sysfunc(prxchange(s/\s+/ /, -1, &glbmvarlist));
    %let glbmvarlist = %sysfunc(prxchange(s/^\s//, -1, &glbmvarlist));
    %let nglbmvar    = %sysfunc(countc(&glbmvarlist, " "));
    %let nglbmvar    = %eval(&nglbmvar + 1);

    %do i = 1 %to &nglbmvar;
        %local glbvar;
        %let glbvar = %scan(&glbmvarlist, &i, " ");

        %if %symexist(&glbvar) = 0 %then 
            %do;
                %global &glbvar;
            %end;
    %end;


    ******************************************************;
    * Hard Code Value;
    ******************************************************;

    %let pdatalibrf    = pdata;
    %let pdatabklibrf  = pdatabk;
    %let debuglibrf    = debug;
    %let sourceLibrf   = source;
    %let tempbklibrf   = temp;


    %let dlm4refdset   = %str(,);
    %let dlm4refvar    = %str(,);
    %let dlm4sdset     = %str(,);

    %let IsErr         = 0;
    %let blank         = ;

    %let allsiteTXT    = %str(<__ALLSITE__>);
    %let alldsetTXT    = %str(<__ALLDSET__>);
    %let allIssueTXT   = %str(<__ALLISSUE__>);
    %let allSubjectTXT = %str(<__ALLSUBJECT__>);

    %let dvpconfigdset           = %str(_dvpConfig);
    %let dvpRefConfigDset        = %str(_dvpRefConfig);
    %let dvpSDsetConfigDset      = %str(_dvpSdsetConfig);
    %let dvpALLissueTypeDset     = %str(_dvpALLissueType);
    %let dsetSummaryDset         = %str(_dvpSdsetSummary);
    %let issueSummaryDset        = %str(_dvpIssueSummary);
    %let subjectSummaryDset      = %str(_dvpSubjectSummary);
    %let subjectIssueSummaryDset = %str(_dvpSubjectIssueSummaryDset);
    %let siteSummaryDset         = %str(_dvpSiteSummary);
    %let deletedIssueDset        = %str(_dvpDeletedIssues);
    %let QstatSummaryDset        = %str(_dvpQstatSummary); 
    %let namingRangeDset         = %str(_dvpNameRange);
    %let updateTBL               = %str(_dvpUpdateTBL); /* imported from update file. contains updated deletion flag and q2 comment for each issue */
    %let nobsTBL                 = %str(_dvpNOBStbl); /* contains all record ID and its number of non-deleted records  */
    %let MD5TBL                  = %str(__MD5);  /* contains all record ID and deletion flag and Q2 Comment */


    /* summary dataset name for a site */
    %let _siteSubjSumDset  = %str(_siteSubjSumDset);
    %let _siteDsetSumDset  = %str(_siteDsetSumDset);
    %let _siteIssueSumDset = %str(_siteIssueSumDset);

    /*
    * Used when compare is N. Displayed in every other record;
    %let skipColor     = %str(#DBEEF3); 
    * Used in summary sheet summary line (proc report break statement);
    %let breakColor    = %str(#FDF3D9); 
    * Color used for new issue records;
    %let newcolor      = %str(pink);
    * Color used for modified issue records;
    %let mdfcolor      = %str(#FFF2CC);
    */


%mend GlbMvars;
