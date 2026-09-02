libname ipeds '~/IPEDS';
options fmtsearch=(IPEDS);


proc sql;
  create table predictors as
  select *
  from (ipeds.characteristics as char inner join ipeds.tuitionandcosts as cost
      on char.unitID eq cost.unitID) inner join
        ipeds.salaries(where=(rank eq 7)) on char.unitID eq salaries.unitID
  order by unitID
  ;
quit;

proc sort data=predictors out=check dupout=dups nodupkey;
  by unitid;
run;

