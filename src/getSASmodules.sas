/*
    Program Name: getSASModules.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2013/10/15
        
    Get a list of available SAS modules

*/


filename setinit namepipe '\\.\pipe\setinit' server retry=60;
/* This code writes three records into the named pipe called setinit.      */

option ls=256;
proc printto log=setinit;
run;

proc setinit; run;
