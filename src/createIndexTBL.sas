/*
    Program Name: createIndexTBL.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/20

    Create index table before printing issue datasets.
*/

%macro createIndexTBL(preIndex=, indexStartRowNum=, indexHeaderNum=, issueHeaderNum=, skipLineNum=, returnlink=, sheetname=);

    proc sort data  = &preIndex; by issueid; run;

    data __index;
        set &preIndex nobs=_nobs_;
        nobs2 = lag(nobs);
        retain  _issueheadernum _1stissuestartnum;
        if _n_ = 1 then
            do;
                _indexstartnum     = &indexStartRowNum; /* index start row number */
                _indexheaddernum   = &indexHeaderNum; /* # of lines of index header number */
                _indexendnum       = _indexstartnum + _nobs_ + _indexheaddernum - 1;  /* index table end line number */
                _1stissuestartnum  = _indexendnum + &skipLineNum + 1; /* first issue start number */
                _issueheadernum    = &issueHeaderNum; /* number of lines of issue dataset header */
            end;
        retain _issuestartnum;
        if _n_ = 1 then _issuestartnum = _1stissuestartnum;
        else _issuestartnum = (_issuestartnum + _issueheadernum + nobs2 -1) + (&skipLineNum + 1) + %if &returnlink = Y %then 1; %else 0;; 
        _issueendnum = _issuestartnum + _issueheadernum + nobs - 1;

        length _range $40 hplink $256;
        _range = "R"||strip(put(_issuestartnum, best.))||"C1"||':R'||strip(put(_issueendnum, best.))||"C1";
        
        hplink = "=HYPERLINK("""||"#'&sheetname'!"||strip(_range)||""", """||strip(issueid)||""")";
    run;

%mend createIndexTBL;
