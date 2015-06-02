   
/*
    Program Name: sasLibInit.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/01/15

    Modification History:

    Ken Cao on 2014/05/13: Move instead of delete dataset in directory NEW.

*/

%macro sasLibInit;

    %if %upcase(&compare) = Y %then
        %do;
            %if %upcase(&rerun) = Y %then
                %do;
                    proc copy in = &pdatalibrf out = &tempbkLibrf move memtype=data;
                    run;
                %end;
            %else
                %do;
                    proc copy in = &pdatabklibrf out = &tempbklibrf move memtype=data; run;
                    proc datasets nolist nodetails;
                        copy in = &pdatalibrf out = &pdatabklibrf move;
                    quit;
                %end;
        %end;
    %else
        %do;
            proc copy in = &pdatalibrf out = &tempbklibrf move memtype=data;
            run;
        %end;
%mend sasLibInit;
