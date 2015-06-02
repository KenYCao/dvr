/*
    Program Name: genRefDsets.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/14

    Combine one or more source datasets
*/

%macro genRefDsets(issueid =, subject=, out=, outFlyOver=);

    %local refdsets;
    %local nrefdset;
    %local i;
    %local refdset;
    %local refvars;
    %local dsid;
    %local rc;
    %local nvar;
    %local nobs;
    %local j;
    %local varname;
    %local varlabel;
    %local label;
    %local flyover;
    %local k;


    %getRefDsets(&issueid);
    %getNRefDset(&issueid);
        

    data _flyOver;
        length varname $255 label $255 flyover $255 dsetnum 8;
        if 0;
        call missing(varname, label, flyover, dsetnum);
    run;

    %do i = 1 %to &nrefdset;
        %let refdset = %upcase(%scan(&refdsets, &i, " "));

        %getRefVars(&issueID, &refdset);

        data __source;
            set &sourceLibrf..&refdset;
            where &subjectvar = "&subject";
            &refvars; /* keep or drop some varaibles */
        run;
                
        %getDsetInfo(indata=__source, getNOBS = Y, getNVARS = Y);


        %let dsid = %sysfunc(open(__source));
        data _source&i;
            set __source;
            __n + 1;
            %do j = 1 %to &nVar;
                %let varname  = %upcase(%sysfunc(varname(&dsid, &j)));
                rename &varname = _&i._&refdset._&j;
            %end;
        run;

        /*
        proc sql;
            insert into _meta(id, sdset, nobs, varname, newname, varlabel1, varlabel2)
            %do j = 1 %to &nvar;
                %let varname  = %upcase(%sysfunc(varname(&dsid, &j)));
                %let varlabel = %sysfunc(varlabel(&dsid, &j));
                values(&i, "&dsetname", &nobs, "&varname", "_&i._&dsetname._&j", "&dsetname..&varname","&varlabel")
            %end;
            ;
        quit;
        */

        proc sql;
            insert into _flyOver(varname, label, flyover, dsetnum)
            %do j = 1 %to &nvar;
                %let varname  = %upcase(%sysfunc(varname(&dsid, &j)));
                %let varlabel = %bquote(%sysfunc(varlabel(&dsid, &j)));
                %let varlabel = %bquote(%sysfunc(prxchange(s/[""]/""/, -1, &varlabel)));
                %if &reverseVarNameLBL = Y %then %do;
                    %let label   = &refdset..&varname;
                    %let flyover = &varlabel;
                %end;
                %else %do;
                    %let flyover = &refdset..&varname;
                    %let label   = &varlabel;
                %end;
                values("_&i._&refdset._&j", "&label", "&flyOver", &i)
            %end;
            ;
        quit;

        %let rc = %sysfunc(close(&dsid));
    %end;


    * for review purpose, merge reference source dataset with issue dataset;
    %if &reviewonly = Y %then %do;
        %issueDsetPrintSetup(indata=&pdataLibrf..&issueID, issueid = &issueID, out=_issueDset, outFlyover= _issueDsetFlyOver);
        %getDsetInfo(indata=_issueDset(where=(&subjectVar = "&subject") drop=_type_ _diff2_ _diff3_ _mdfnum_ __q2cmnt __odd), getNOBS = Y, getNVARS = Y);

        %let disd = %sysfunc(open(_issueDset));
        %let k    = 0;
        data _source0;
            set _issueDset;
            where &subjectVar = "&subject";
            drop _type_ _diff2_ __q2cmnt __odd;
            %do j = 1 %to &nVar;
                %let varname  = %upcase(%sysfunc(varname(&dsid, &j)));
                %if &varname ^= __RECID %then %do;
                %let k = %eval(&k + 1);
                rename &varname = _0_&issueid._&k;
                %end;
            %end;
            __n + 1;
        run;

        proc sql;
            insert into _flyOver(varname, label, flyover, dsetnum)
            values ("__RECID", "Record ID", " ", 0);
        quit;

        proc sql;
            insert into _flyOver(varname, label, flyover, dsetnum)
            select 
                "_0_&issueID._"||strip(put(monotonic(), best.)),
                label,
                flyover,
                0
            from _issueDsetFlyOver;
        quit;
        /*
        proc sql;
            insert into _meta(id, sdset, nobs, varname, newname, varlabel1, varlabel2)
            %do j = 1 %to &nvar;
                %let varname  = %upcase(%sysfunc(varname(&dsid, &j)));
                %let varlabel = %sysfunc(varlabel(&dsid, &j));
                values(0, "&issueID", &nobs, "&varname", "_0_issueVar_&j", "&varname","&varlabel")
            %end;
            ;
        quit;
        */
        %let rc = %sysfunc(close(&dsid));
    %end;

    data _refDset0;
        %if &reviewonly = Y %then %do;
            merge _source0 %do i = 1 %to &nrefdset;  _source&i %end;
            ;
                by __n;
        %end;
        %else %do;
            %if &nrefdset  = 1 %then set _source1;
            %else %do;
                merge 
                %do i = 1 %to &nrefdset;
                    _source&i 
                %end;
                ;
                by __n:
            %end;
            ;
        %end;
        drop __n;
    run;

    data &out;
        set _refDset0;
    run;

    %if &outFlyOver > 0 %then %do;
        data &outFlyOver;
            set _flyOver;
        run;
    %end;
 
%mend genRefDsets;
