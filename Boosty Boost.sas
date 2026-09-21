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
          selection=stepwise(select=AIC choose=AIC);
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

/* proc univariate data=results; */
/*   var residual Zresidual; */
/*   id county state; */
/* run; */

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
          selection=stepwise(select=AIC choose=AIC);
  weight weight;
run;


proc glm data=reweightCDI;
  class region;
  model crimeRate = &_glsind1;
  *output out=results predicted=predicted r=residual
                      rstudent=Zresidual;
run;

/*I would tend to prefer a weighting function rather than a simple
  discrete reweighting scheme.

  Often these are based on a logistic / sigmoidal function, but
    reflected around the center point...

    e^|?|/(1+e^|?|) with some other modifiers perhaps*/

data reweightCDI2;
  set results;

  weight = exp(abs(Zresidual))/(1+ exp(abs(Zresidual))) + 1/2;
    /**Error/Zresidual 0 stays at weight 1,
        any other error lets weight grow from there to a maximum of 1.5*/
run;

proc glmselect data=reweightCDI2;
  class region;
  model crimeRate = pop18_34 -- over65 hs_grad--inc_per_cap 
          popDensity physicianRate HospitalBedRate /
          selection=stepwise(select=AIC choose=AIC);
  weight weight;
run;


proc glm data=reweightCDI2;
  class region;
  model crimeRate = &_glsind1;
run;/**AIC side looks different, but still lands at same place
      with SBC choosing because even though I reweighted everything
        I didn't reweight much */

proc sgplot data=reweightCDI2;
  pbspline x=Zresidual y=weight;
run;


data reweightCDI3;
  set results;

  weight = exp(2*abs(Zresidual))/(1+exp(2*abs(Zresidual))) + 1/2;
run;

proc sgplot data=reweightCDI3;
  pbspline x=Zresidual y=weight;
run;

proc glmselect data=reweightCDI3;
  class region;
  model crimeRate = pop18_34 -- over65 hs_grad--inc_per_cap 
          popDensity physicianRate HospitalBedRate /
          selection=stepwise(select=AIC choose=AIC);
  weight weight;
run;


proc glm data=reweightCDI3;
  class region;
  model crimeRate = &_glsind1;
run;


data reweightCDI4;
  set results;

  weight = 3*exp(2*abs(Zresidual))/(1+exp(2*abs(Zresidual))) + 1/2;
run;

proc sgplot data=reweightCDI4;
  pbspline x=Zresidual y=weight;
run;

proc glmselect data=reweightCDI4;
  class region;
  model crimeRate = pop18_34 -- over65 hs_grad--inc_per_cap 
          popDensity physicianRate HospitalBedRate /
          selection=stepwise(select=AIC choose=AIC);
  weight weight;
run;


proc glm data=reweightCDI4;
  class region;
  model crimeRate = &_glsind1;
run;


data reweightCDI5;
  set results;
  if abs(Zresidual) le 1 then weight=1;
    else weight = 3*exp(2*abs(Zresidual))/(1+exp(2*abs(Zresidual))) + 1/2;
run;

proc sgplot data=reweightCDI5;
  pbspline x=Zresidual y=weight;
run;

proc glmselect data=reweightCDI5;
  class region;
  model crimeRate = pop18_34 -- over65 hs_grad--inc_per_cap 
          popDensity physicianRate HospitalBedRate /
          selection=stepwise(select=AIC choose=AIC);
  weight weight;
run;


proc glm data=reweightCDI5;
  class region;
  model crimeRate = &_glsind1;
run;
