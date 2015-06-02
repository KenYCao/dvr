/*
    Program Name: functions.sas
        @Author: Ken Cao (yong.cao@q2bi.com)
        @Initial Date: 2014/07/03
*/

proc fcmp outlib=work.func.dvr;
    /* check existence of a variable in a dataset */
    function chkvar(varname $, dsetname $);
        dsid   = open(dsetname);
        if dsid = 0  then do;
            return (-1);
        end;
        varnum = varnum(dsid, varname);
        rc     = close(dsid);
        return (varnum); 
    endsub;
run;



proc fcmp outlib=work.func.dvr;
    function linefeed(instr $, odsEscapeChar $) $;
        length outstr $1024;
        outstr = tranwrd(instr, '0D'x, '0A'x);
        outstr = prxchange('s/(\cJ)+/$1/', -1, instr);
        outstr = tranwrd(instr, '0A'x, strip(odsEscapeChar)||'n');
        return (outstr);
    endsub;
run;


/* get # of observations */
proc fcmp outlib=work.func.dvr;
    function getnobs(indata $);
        dsid = open(indata);
        if dsid = 0 then return(0);
        nobs = attrn(dsid, 'nlobsf');
        rc   = close(dsid);
        return (nobs);
    endsub;
run;
