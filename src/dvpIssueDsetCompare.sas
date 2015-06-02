/*
    Program Name: dvpIssueDsetCompare.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/03/12

    Compare issue datasets. This program use __KeyID and __RecID when compare.


    Revision History:
    Ken Cao on 2015/02/12: Add _diff3_ to store compare difference that will be used 
                           to highlight changed variale later.
*/




%macro dvpIssueDsetCompare(issueID=, comparevars=);


    %local ncompvar;
    %local i;

    %stripCompbl(comparevars, &comparevars);

    %if %length(&comparevars) = 0 %then %let ncompvar = 0;
    %else %let ncompvar = %eval(%sysfunc(countc(&comparevars, " ")) + 1);

    %do i = 1 %to &ncompvar;
        %local compvar&i;
        %let compvar&i = %upcase(%scan(&comparevars, &i, " "));
    %end;

    proc sort data = &pdatabklibrf..&issueID
    out = __old(keep=__recid __keyid %do i = 1 %to &ncompvar; &&compvar&i %end;
                rename=(__recid = _old___recid %do i = 1 %to &ncompvar; &&compvar&i = _old_&&compvar&i  %end;));
        by __keyid;
    run;

    data _compRslt;
        merge &pdatalibrf..&issueID (in  = _new)
              __old (in = _old)
        ;
        by __KeyID;

        if _new;

        if not _old then _type_ = 'N';
        else if __recid ^= _old___recid then _type_ = 'M';
        
        length _msg _msg2 _msg3 $32767 _mdfnum_ 8;

        _mdfnum_ = 0; /* # of modifications */

        if _type_ ^= 'M' then return;

        %do i = 1 %to &ncompvar;
        if &&compvar&i ^= _old_&&compvar&i then
            do;
                _mdfnum_ = _mdfnum_ + 1;

                ** Ken Cao on 2014/12/22: Use SAS Function VVALUE to retrive formatted value of a variable;
                 %*any2char(indata = __old, invar = _old_&&compvar&i);

                 _msg  = '<Modification '||strip(put(_mdfnum_, best.))
                        ||", value of Query Variable &i in last version: ["|| strip(vvalue(_old_&&compvar&i)) ||'] >';
                 _msg2 = '<Modification '||strip(put(_mdfnum_, best.))
                        ||", value of &&compvar&i in last version: ["|| strip(vvalue(_old_&&compvar&i))||'] >';
                 _msg3 ="&&compvar&i: "|| strip(vvalue(_old_&&compvar&i));

                 _diff_ = ifc(_diff_ > ' ', strip(_diff_)||_msg, _msg);
                 _diff2_ = ifc(_diff2_ > ' ', strip(_diff2_)||_msg2, _msg2);
                 _diff3_ = ifc(_diff3_ > ' ', strip(_diff3_)||'@'||_msg3, _msg3);
            end;
        %end;

        if _diff2_ = ' ' or _diff_ = ' ' then do;
            put 'ERR' 'OR: _TYPE_ is set to M, but no report variables found different.' @@;
            put ' Record ID: ' __recid;
        end;

        * display record ID of last version for modified issue records;
        
        if _diff_ > ' ' then do;
/*            _diff_  = 'Record ID in last version: '||strip(_old___recid)||'0A'x||strip(_diff_);*/
            _diff2_ = 'Record ID in last version: '||strip(_old___recid)||'0A'x||strip(_diff2_);
        end;
        


        keep __recid _type_ _diff_ _diff2_ _diff3_ _mdfnum_;
        rename _type_  = _type_2;
        rename _diff_  = _diff_2;
        rename _diff2_ = _diff2_2; 
        rename _diff3_ = _diff3_2; 
        rename _mdfnum_ = _mdfnum_2; 
    run;

    proc sort data = _compRslt; by __recid; run;
    /*
    data &pdatalibrf..&issueID;
        merge &pdatalibrf..&issueID _compRslt;
            by __recid;
    run;
    */

    data &pdatalibrf..&issueDset;
        set _compRslt;
        do until (_iorc_ = %sysrc(_dsenom));
            modify &pdatalibrf..&issueDset key = __recid;
            select (_iorc_);
                when (%sysrc(_sok)) do; 
                    _type_   = _type_2; 
                    _diff_   = _diff_2;
                    _diff2_  = _diff2_2;
                    _diff3_  = _diff3_2;
                    _mdfnum_  = _mdfnum_2;
                    replace &pdatalibrf..&issueDset;
                end;
                when (%sysrc(_dsenom)) do;
                    _error_ = 0; 
                end; 
                otherwise;
            end;
        end;
     run;

%mend dvpIssueDsetCompare;
