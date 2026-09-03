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

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt sa:;
  fcs;
run;

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt sa:;
  fcs reg(tuition3 / details);
    /**I can see imputation model details on any of the things
        that need imputation*/
  fcs reg(roomamt / details); /**Each specification requires a separate FCS 
                              statement*/
run;

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt 
          sa09mct sa09mot;
  fcs reg(tuition3 / details);
  fcs reg(roomamt / details); 
run;

proc means data=predImputed mean stderr;
  class _imputation_;
  var tuition3;
  ods output summary=imps;
run;
proc means data=imps mean var uss;
  var tuition3_mean tuition3_stderr;
run;

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt 
          sa09mct sa09mot;
  fcs reg(tuition3 = control hloffer sa09mct sa09mot / details);
  /**I can pick predictor sets as a subset of the var list 
        in my reg specification */
run;

proc mi data=predictors out=predImputed;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt 
          sa09mct sa09mot;
  fcs reg(tuition3 = control hloffer sa09mct sa09mot / details);
  /**I can also make these sequential... */
  fcs reg(roomamt = room control hloffer sa09mct sa09mot tuition3 / details);
  fcs reg(boardamt = board control hloffer sa09mct sa09mot tuition3 roomamt/ details);
run;

data predictors2;
  set predictors;
  if put(room,room.) eq 'No' then do; roomamt = -1; roomcap = -1; end;
  if put(board,board.) eq 'No' then boardamt = -1;
run;/**Clean up these missings that should not be imputed*/

proc mi data=predictors2 out=predImputed2 seed=2468;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt 
          sa09mct sa09mot;
  fcs reg(tuition3 = control hloffer sa09mct sa09mot);
  /**I can also make these sequential... */
  fcs reg(roomamt = room control hloffer sa09mct sa09mot tuition3);
  fcs reg(boardamt = board control hloffer sa09mct sa09mot tuition3 roomamt);
run;

proc mi data=predictors2 out=predImputed2 seed=2468;
  class iclevel control hloffer instcat room board;
  var iclevel control hloffer instcat room board tuition3 roomamt boardamt 
          sa09mct sa09mot;
  fcs reg(tuition3 = control sa09mct sa09mot);
  /**I can also make these sequential... */
  fcs reg(roomamt =  control sa09mct sa09mot tuition3);
  fcs reg(boardamt =  control sa09mct sa09mot tuition3 roomamt);
run;

/**Bring in the graduation rates/categories and fit a model (or a selection run)
  for each imputation and see what kind of variation that introduces into
  my predictive model
  
  Bring in grad rates/categories, do some regression, analyze (PROC MIANALYZE)*/
