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

proc means data=predictors nmiss;
run;


/**For a multiple imputation, we will specify:
  1. input and output data sets
  2. variables to use or impute as CLASS (categorical) or VAR (all)
  3. an imputation method */

/**simple version... */
proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition1--fee3 roomcap roomamt boardamt sa:;
  fcs;/*fcs->full conditional specification does not assume
        any hierarchy in the missingness of values
        does not need any more detailed specifications but some are available*/
run;

/*I may want to be careful about missings--sometimes they should be structurally
  encoded to something and not imputed (or just left out of the imputation)
  as should be the case for Roomcap here, it is missing exactly when room is 2/No*/

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition1--fee3 roomamt boardamt sa:;
  fcs;
run;

proc means data=predImputed;
  var tuition: roomamt boardamt;
run;

proc means data=predictors;
  var tuition: roomamt boardamt;
run;

/**Still not looking great for tuition imputations...*/
proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition1--fee3 roomamt boardamt sa:;
  fcs;
run;

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt sa:;
  fcs;
run;


proc means data=predImputed;
  var tuition: roomamt boardamt;
run;

proc sgplot data=predImputed;
  hbox tuition3;
run;

proc mi data=predictors out=predImputed minimum=0;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt sa:;
  fcs;
run;


proc means data=predImputed;
  var tuition: roomamt boardamt;
run;

proc sgplot data=predImputed;
  hbox tuition3;
run;

proc mi data=predictors out=predImputed minimum=0;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt sa:;
  fcs reg(tuition3 = iclevel roomamt);
run;