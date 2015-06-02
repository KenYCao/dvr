
%macro rm_nulldatasets(prefix=); /*remove null datasets*/
    %local _nulmem_;

    proc sql noprint;
        select distinct memname 
        into: _nulmem_ separated by ' '
        from dictionary.tables
        where libname='PDATA' 
        and nobs=0 
        and memname like "%upcase(&prefix)%";
    quit;    

    %if %length(&_nulmem_)>0 
    and %upcase(&testmode) ^= Y  
    %then 
        %do;
            proc datasets library=PDATA nolist nodetails;
                delete &_nulmem_;
            quit;
        %end;
%mend rm_nulldatasets; 
