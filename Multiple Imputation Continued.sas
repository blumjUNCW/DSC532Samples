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

proc format;
    value miss
     .='Missing'
     other='Present'
     ;
run;

options nolabel;
Title 'Tuition 3';
proc freq data=predictors;
  table tuition3*(control--cbsatype room roomcap board roomamt boardamt sa09: 
                  tuition1 tuition2 fee:)
        / missing;
  format _numeric_ miss.;
run;

options nolabel;
Title 'RoomCap';
proc freq data=predictors;
  table roomcap*(control--cbsatype room board sa09: tuition3)  
        / missing;
  format _numeric_ miss.;
run;

options nolabel;
Title 'RoomAmt';
proc freq data=predictors;
  table roomamt*(control--cbsatype room board sa09: tuition3)  
        / missing;
  format _numeric_ miss.;
run;

options nolabel;
Title 'BoardAmt';
proc freq data=predictors;
  table boardamt*(control--cbsatype room board sa09: tuition3)  
        / missing;
  format _numeric_ miss.;
run;