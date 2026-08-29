
%macro hpforestbase(vars,trees,inbag,depth,select,
                library,table,quant,cat,target,targetType);
proc hpforest data=&library..&table 
              vars_to_try=&vars
              maxtrees=&trees
              inbagfraction=&inBag
              maxdepth=&depth
              preselect=&select;
  target &target / Level=&TargetType;
  input &quant / Level=interval;
  input &cat / Level=nominal;
  ods output fitStatistics=fit VariableImportance=vi;
run;
%mend;

%macro cases(varToTry=2 4 6, treeAmt=60 80 100, inbagProp=.5 .6 .7, 
             TreeDepths=5 10 20, select=binnedsearch, 
             library=,table=,quant=,cat=,target=,TargetType=);
     proc datasets lib=work;
      delete AllFits AllVI;
     run; /*clean final data out of the work library*/
     %let c1 = 1; /*varToTry counter*/
     %let vt = %scan(&varToTry,&c1);
     %do %until(&vt eq );/*Start of Variables to try loop*/
      %let c2 = 1; /*TreeAmt counter*/
      %let tA = %scan(&treeAmt,&c2);
      %do %until(&ta eq );/*Start number of trees loop*/
        %let c3 = 1; /*InBagProp counter*/
        %let IB = %scan(&InBagProp,&c3,%str( ));
        %do %until(&IB eq );/*In bag proportion loop start*/
          %let c4 = 1; /*TreeDepth counter*/
          %let TD = %scan(&TreeDepths,&c4);
          %do %until(&TD eq );/*Tree depth loop start*/
            %hpforestbase(&vt,&ta,&IB,&TD,&select,&library,&table,&quant,&cat,&target,&targetType);
              /*Ask for the forest...*/
            data fit;
              set fit;
              depth=&TD;
              InBag=&IB;
              TreeAmount=&TA;
              Vars=&VT;
            run;/*update the fit data to include the parameter choices for that case*/
            proc append base=AllFits data=fit;
            run;/*Add that data to the full fit data set*/
            data vi;
              set vi;
              depth=&TD;
              InBag=&IB;
              TreeAmount=&TA;
              Vars=&VT;
            run;
            proc append base=AllVI data=VI;
            run;/*same with variable importance*/              
            %let c4 = %eval(&c4+1);
            %let TD = %scan(&TreeDepths,&c4);
          %end;/*Tree depth loop end*/
          %let c3 = %eval(&c3+1);        
          %let IB = %scan(&InBagProp,&c3,%str( ));
        %end;/*In bag proportion loop end*/
        %let c2 = %eval(&c2+1);
        %let tA = %scan(&treeAmt,&c2);
      %end;/*End number of trees loop*/
      %let c1 = %eval(&c1+1);
      %let vt = %scan(&varToTry,&c1);
     %end;/*End of Variables to try loop*/

     proc sort data=allfits;
          by treeAmount inbag vars depth;
      run;

      ods select all;
      proc sgpanel data=allfits;
        by inbag TreeAmount;
        panelby vars depth / layout=lattice;
        series x=NTrees y=predOob;
        series x=NTrees y=predAll;
        rowaxis grid;
        colaxis grid;
      run;


      proc sgplot data=allVI;
        %if(%upcase(&TargetType) eq NOMINAL) %then %do;
          hbox giniOOB / category=variable;
        %end;
        %else %do;
          hbox mseOOB / category=variable;
        %end;
      run;
%mend;

libname SASData '~/SASData';

options nomprint nomlogic nosymbolgen nonotes;
ods trace off;
/**If it's running well, minimize the log */
ods select none;
/*don't want to read output tables*/
%cases(library=SASData,table=cdi,quant=land--inc_tot,
        target=region,TargetType=nominal,treeAmt=80);


data cdi;
  set sasdata.cdi(drop=inc_tot);
  popDensity = pop/land;
  crimeRate = crimes/pop;
  docPerCap = physicians/pop;
  hospitalPerCap = beds/pop;
run;

ods select none;
%cases(library=work,table=cdi,quant=land--inc_per_cap popDensity--hospitalPerCap,
        target=region,TargetType=nominal,treeAMT=80);
