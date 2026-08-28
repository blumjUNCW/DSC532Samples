libname SASData '~/SASData';

%macro hpforest(vars=4,trees=100,inbag=.7,depth=20,select=binnedsearch,
                library=,table=,quant=,cat=,target=,targetType=);
proc hpforest data=&library..&table 
              vars_to_try=&vars
              maxtrees=&trees
              inbagfraction=&inBag
              maxdepth=&depth
              preselect=&select;
  target &target / Level=&TargetType;
  input &quant / Level=interval;
  input &cat / Level=nominal;
run;
%mend;

ods trace on;
%hpforest(library=SASData,table=cdi,quant=land--hs_grad poverty--inc_tot,
          cat=region,target=ba_bs,TargetType=interval);


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

%macro cases(varToTry=4 6 8, treeAmt=60 80 100, inbagProp=.6 .7 .8, TreeDepths=10 15 20,
            select=binnedsearch, library=SASData,table=cdi,quant=land--hs_grad poverty--inc_tot,
            cat=region,target=ba_bs,TargetType=interval);
     %let c1 = 1; /*varToTry counter*/
     %let vt = %scan(&varToTry,&c1);
     %do %until(&vt eq );
      %let c2 = 1; /*TreeAmt counter*/
      %let tA = %scan(&treeAmt,&c2);
      %do %until(&ta eq );
        %let c3 = 1; /*InBagProp counter*/
        %let IB = %scan(&InBagProp,&c3,%str( ));
        %do %until(&IB eq );
          %let c4 = 1; /*TreeDepth counter*/
          %let TD = %scan(&TreeDepths,&c4);
          %do %until(&TD eq );
            %hpforestbase(&vt,&ta,&IB,&TD,&select,&library,&table,&quant,&cat,&target,&targetType);
            data fit;
              set fit;
              depth=&TD;
              InBag=&IB;
              TreeDepth=&TD;
              Vars=&VT;
            run;
            proc append base=AllFits data=fit;
            run;
            data vi;
              set vi;
              depth=&TD;
              InBag=&IB;
              TreeDepth=&TD;
              Vars=&VT;
            run;
            proc append base=AllVI data=VI;
            run;              
            %let c4 = %eval(&c4+1);
            %let TD = %scan(&TreeDepths,&c4);
          %end;
          %let c3 = %eval(&c3+1);        
          %let IB = %scan(&InBagProp,&c3,%str( ));
        %end;
        %let c2 = %eval(&c2+1);
        %let tA = %scan(&treeAmt,&c2);
      %end;
      %let c1 = %eval(&c1+1);
      %let vt = %scan(&varToTry,&c1);
     %end;
%mend;
options nomprint nomlogic nosymbolgen nonotes;
ods select none;
ods trace off;
%cases;