
/*
    Get Dataset Attributes.
*/

%macro getDsetInfo(indata=,getNOBS=,getLabel=,getNVARS=, getIsIndex=);
    %local dsid;
    %local rc;
    %local _nobs_;
    %local _label_;
    %local _nvars_;
    %local _isIndex_;

    %let dsid = %sysfunc(open(&indata));
    %if &dsid = 0 %then
        %do;
            %put ERR%str(&blank)OR: Dataset %upcase(&indata) could not be opened;
            %return;
        %end;
    
    %let _label_   = %nrbquote(%sysfunc(attrc(&dsid,label)));
    %let _nobs_    = %sysfunc(attrn(&dsid,nlobsf));
    %let _nvars_   = %sysfunc(attrn(&dsid,nvar));
    %let _isIndex_ = %sysfunc(attrn(&dsid, isindex));

    
    %let rc = %sysfunc(close(&dsid));

    %if %upcase(&getNOBS)    = Y  %then %let nobs     = %nrbquote(&_nobs_);
    %if %upcase(&getLabel)   = Y  %then %let label    = %nrbquote(&_label_); 
    %if %upcase(&getNVARS)   = Y  %then %let nvar     = %nrbquote(&_nvars_); 
    %if %upcase(&getIsIndex) = Y  %then %let isIndex  = %nrbquote(&_isIndex_); 

%mend getDsetInfo;
