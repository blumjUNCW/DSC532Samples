libname SASData '~/SASData';

data cdi;
  set sasdata.cdi;

  crimeRate=crimes/pop*1000;
  popDensity=pop/land;
  physicianRate=physicians/pop;
  HospitalBedRate=Beds/pop;
run;

/**Pick best glm for crime rate with single-factor
    predictor choices*/
proc glmselect data=cdi;
  class region;
  model crimeRate = pop18_34 -- over65 hs_grad--inc_per_cap 
          popDensity physicianRate HospitalBedRate /
          selection=stepwise(select=AIC choose=SBC);
run;
/** "Boost" this model...
      reweight the data in a way that you think 
      may lead to a better model choice
      
      see if it worked*/

proc glm data=cdi;
  class region;
  model crimeRate = &_glsind1;
  output out=results predicted=predicted r=residual
                      rstudent=Zresidual;
  /*Boosting is based on errors...*/
run;

proc univariate data=results;
  var residual Zresidual;
  id county state;
run;

data reweightCDI;
  set results;
  /**"Boost" weight on ones with more error...*/
  if abs(Zresidual) gt 2.5 then weight = 1.5;
    else if abs(Zresidual) gt 1.75 then weight = 1.25;
      else weight = 1;
run;

proc glmselect data=reweightCDI;
  class region;
  model crimeRate = pop18_34 -- over65 hs_grad--inc_per_cap 
          popDensity physicianRate HospitalBedRate /
          selection=stepwise(select=AIC choose=SBC);
  weight weight;
run;


proc glm data=reweightCDI;
  class region;
  model crimeRate = &_glsind1;
  weight weight;
  *output out=results predicted=predicted r=residual
                      rstudent=Zresidual;
run;