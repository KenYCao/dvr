%macro m_varib(dis=); /*Check duplicated records in raw data*/
	proc sql;
	 create table test&dis as
	 select distinct name
	 from dictionary.columns
	 where libname="SOURCE" and memname=upcase("&dis");
	quit;
	data test1&dis;
	 set test&dis;
	 if name="ID" then delete;
	run;
	proc sql; 
	 select name into: var_&dis  separated by ','
	 from  test1&dis;
	quit;

	proc sql;
	 create table out.&dis._9001 as
	  select *,
	/*  3 as VAL_FLG,*/
		"&dis" as SURCE,
	/*	"External Electronic" as CHECKTYPE,*/
	  	"Duplicated records exist, please clarify." as MESSAGE,
		"DCF" as TYPE
	  from source.&dis
	  group by &&var_&dis
	     having count(*)>1;
	quit;
%mend;
