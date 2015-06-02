/*
    Program Name: getIssueMeta.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/03

    Get meta information of a issue.

    Ken Cao on 2014/12/05: Add %BQUOTE function to balance single quotation mark.
	Ken Cao on 2015/01/21: Mask ampersand and percent sign in the value.

*/


%macro getIssueMeta(issueid, getMsg=, getSdset=, getsdsetlbl=, getIssueType=);

    %local _msg_;
    %local _sdset_;
    %local _sdsetlbl_;
    %local _issueType_;

    data _null_;
        set &dvpConfigDset;
        where issueid = "&issueid";
        length msg $2048;
        msg = prxchange('s/[""]/%str("")/', -1, message);
        *put msg = ;
        sdsetlbl  = prxchange('s/[""]/%str("")/', -1, sdsetlbl);
        sdsetlbl  = tranwrd(sdsetlbl, '0A'x, '; ');
        sdsetlbl  = tranwrd(sdsetlbl, '0D'x, '; ');
        call symput('_msg_', strip(msg));
        call symput('_sdset_', strip(upcase(sdset)));
        call symput('_sdsetlbl_', '%nrstr('||strip(sdsetlbl)||')');
        call symput('_issueType_', strip(upcase(issuetyp)));
    run;


    %if &getMsg = Y %then %let msg = %bquote(&_msg_);
    %if &getSdset = Y %then %let sdset = &_sdset_;
    %if &getsdsetlbl = Y %then %let sdsetlbl = %bquote(&_sdsetlbl_);
    %if &getIssueType = Y %then %let issueType = &_issueType_;


%mend getIssueMeta;
