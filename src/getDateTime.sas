/*
    Program Name: getDateTime.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Intial Date: 2014/03/07
*/


%macro getDateTime();

    data _null_;
        time = scan(put(time(),is8601dt.),2,'T');
        time = translate(time,"-",':');
        date = put(input("&sysdate9", date9.), yymmdd10.);
        call symput('time', strip(time));
        call symput('date', strip(date));
    run;

%mend getDateTime;
