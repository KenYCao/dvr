******************************************************************************;
* Module: Other                                                              *;
* Type: Sas Macro                                                            *;
* Program Name: getvarinfo.sas                                               *;
* Function: Get variable information in given datasets                       *;
* Initial Date: 2013-01-17                                                   *;
* Author: Ken Cao (yong.cao@q2bi.com)                                        *;
******************************************************************************;

%macro getvarinfo(indata=,invar=,getvarnum=N,getvartype=N,getvarlen=N,getvarlabel=N,getvarfmt=N,getvarinfmt=N);
	%local dsid;
	%local rc;
	%local _varnum_;
	%local _vartype_;
	%local _varlen_;
	%local _varlabel_;
	%local _varfmt_;
	%local _varinfmt_;

	%let dsid=%sysfunc(open(&indata));
	%let _varnum_=%sysfunc(varnum(&dsid, &invar));
	%if &_varnum_>0 %then %do;
		%let _vartype_=%sysfunc(vartype(&dsid, &_varnum_));
		%let _varlen_=%sysfunc(varlen(&dsid, &_varnum_));
		%let _varlabel_=%nrbquote(%sysfunc(varlabel(&dsid, &_varnum_)));
		%let _varfmt_=%sysfunc(varfmt(&dsid, &_varnum_));
		%let _varinfmt_=%sysfunc(varinfmt(&dsid, &_varnum_));
	%end;
/*	
	%put &_varnum_;
	%put &_vartype_;
	%put &_varlen_;
	%put &_varlabel_;
	%put &_varfmt_;
	%put &_varinfmt_;
*/

	%let rc=%sysfunc(close(&dsid));

	%if &getvarnum=Y %then %let varnum=&_varnum_;
	%if &getvartype=Y %then %let vartype=&_vartype_;
	%if &&getvarlen=Y %then %let varlen=&_varlen_;
	%if &getvarlabel=Y %then %let varlabel=&_varlabel_;
	%if &getvarfmt=Y %then %let varfmt=&_varfmt_;
	%if &getvarinfmt=Y %then %let varinfmt=&_varinfmt_;
%mend getvarinfo;
