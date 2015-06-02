/*
    Program Name: getALLsites.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/04/01

   Get all sites
*/

%macro getALLsites();
    
    
    * count # of sites;
    proc sql noprint;
        select distinct 
            count(distinct site), 
            site        
        into
            : nsite, 
            : ALLsites
        separated by "@"
        from &dsetSummaryDset
        ;
    quit;


%mend getALLsites;
