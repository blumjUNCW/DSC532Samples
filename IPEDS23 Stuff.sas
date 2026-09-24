libname IPEDS23 '~/IPEDS23';

options fmtsearch=(IPEDS23);

proc contents data=ipeds23._all_ varnum;
run;

/**Should be able to get all data together merging on
  UnitID -- they're all sorted
  
  build models to predict c21enprf--skip NA category and
      don't use any other directly related measures as predictors*/


data step1;
  merge IPEDS23.adm23(in=adm)
        IPEDS23.degRatio23(in=Deg)
        IPEDS23.drvadm23(in=drvadm)
        IPEDS23.drvhr23(in=HR)
        IPEDS23.ef23d(in=ef)
        IPEDS23.Financial(in=Fin)
        IPEDS23.grads23(in=grads) 
        IPEDS23.HeadCount23(in=HC) 
        IPEDS23.ic2023(in=IC)
        IPEDS23.pell23(in=pell) 
        IPEDS23.sfa23p(in=sfa)
        IPEDS23.hd23(in=hd)
        ;/**match records in all of these*/
  by unitid;/*on their unitID*/
  
  if adm and Deg and drvadm and HR and ef 
      and Fin and grads and hd and hc 
      and ic and pell and sfa; 
    /* It must have a contribution from each table */

run;

proc sort data=step1 nodupkey;
  by unitid;
run;

proc format lib=ipeds23 cntlout=IPEDS23Formats;
run;

proc contents data=step1 varnum;
  ods output position=variables;
run;

/**Split into categorical/quantitative
    check missing or N/A amounts*/

data categorical quantitative;
  set variables;
  where type eq 'Num' and substr(variable,1,3) ne 'C21';
  /**Elim char
      remove all Carnegie (response and others) */

  if anyalpha(format) then output categorical;
    else output quantitative;
run;

proc freq data=step1;
  table c21enprf;
run;

data CatList;
  set categorical end=last;
  length list $1500;
  where variable not contains 'NONCRDT';

  retain list;

  list=catx(' ',list,variable);
  if last then do;
      output;
      call symputx("CatList",list);
  end;
  keep list;
run;
%put &CatList;


proc format;
   value miss 
    low-0 = 'Not defined'
    0<-high = 'Defined'
    ;
run; 

%macro missingCat;
proc datasets lib=work;
  delete missingCat;
run;

%let c=1;
%let var=%scan(&CatList,&c);

%do %until(&var eq );
  proc freq data=step1;
    table &var / missing;
    format &var miss.;
    ods output onewayfreqs=miss(keep=table percent &var rename=(&var=value)
                                where=(value gt 0));
  run;
  
  proc append base=missingCat data=miss;
  run;
  %let c=%eval(&c+1);
  %let var=%scan(&CatList,&c);
%end;
%mend;
ods select none;
*%missingCat;

%macro missingCheck(list);
proc datasets lib=work;
  delete MissingAmt;
run;

%let c=1;
%let var=%scan(&List,&c);
%do %until(&var eq );
  proc sql;
    %if(&c eq 1) %then %do;
      create table MissingAmt as 
        select "&var" as variable, sum(&var le 0)/count(&var) as missPct
        from step1
        ;
    %end;
    %else %do;
      create table missing as 
        select "&var" as variable, sum(&var le 0)/count(&var) as missPct
        from step1
        ;
      create table MissingAmt as
        select *
        from missing
        union
        select *
        from MissingAmt
        ;
    %end;
  quit;
  %let c=%eval(&c+1);
  %let var=%scan(&List,&c);
%end;
%mend;
ods select none;


%missingCheck(&catlist);
data FinalCat;
  set MissingAmt end=last;
  length list $1500;

  retain list;

  if misspct lt 0.10 then list=catx(' ',list,variable);
  if last then do;
      output;
      call symputx("FinalCat",list);
  end;
  keep list;
run;
%put &FinalCat;

data quantList;
  set quantitative end=last;
  length list $1500;

  retain list;

  list=catx(' ',list,variable);
  if last then do;
      output;
      call symputx("QuantList",list);
  end;
  keep list;
run;
%put &QuantList;
%missingCheck(&quantlist);
data FinalQuant;
  set MissingAmt end=last;
  length list $1500;

  retain list;

  if misspct lt 0.10 then list=catx(' ',list,variable);
  if last then do;
      output;
      call symputx("FinalQuant",list);
  end;
  keep list;
run;
%put &FinalQuant;


proc freq data=step1;
  table c21enprf;
  format c21enprf 1.;
run;
proc freq data=step1;
  table c21enprf;
run;

ods select all;
proc hpgenselect data=step1;
  partition fraction(validate=.3);
  where c21enprf ge 2;
  class &finalCat;
  model c21enprf(order=internal) = &finalCat &finalQuant / 
                                dist=multinomial link=logit;
  selection method=stepwise(choose=validate); 
run;

proc freq data=step1;
  table c21enprf*hloffer;
run;

proc logistic data=step1 order=internal;
  model c21enprf = bacRatio / link=logit;
  where c21enprf ge 2;
  format c21enprf 1.;
  output out=BacRatio predprobs=(I);
run;

data BacRatio;
  set BacRatio;
  from=input(_from_,1.);
  into=input(_into_,1.);
run;
proc freq data=BacRatio;
  table from*into/nocol norow;
  format from into c21enprf.;
run;

ods select all;
proc hpgenselect data=BacRatio(where=(from ne into));
  partition fraction(validate=.3);
  where c21enprf ge 2;
  class &finalCat;
  model c21enprf(order=internal) = &finalCat &finalQuant / 
                                dist=multinomial link=logit;
  selection method=stepwise(choose=validate); 
run;

proc logistic data=BacRatio(where=(from ne into)) order=internal;
  model c21enprf = UGRatio SFTEINST / link=logit;
  where c21enprf ge 2;
  format c21enprf 1.;
  output out=Next predprobs=(I);
run;

data Next;
  set Next;
  from=input(_from_2,1.);
  into=input(_into_2,1.);
run;
proc freq data=Next;
  table from*into/nocol norow;
  format from into c21enprf.;
run;


ods select all;
proc hpgenselect data=step1;
  partition fraction(validate=.3);
  where c21enprf ge 2;
  class &finalCat;
  model c21enprf(order=internal) = &finalCat &finalQuant / 
                                dist=multinomial link=logit;
  selection method=stepwise(choose=validate); 
  output out=results pred role;
  id _numeric_;
run;



/*

ods select none;
proc logistic data=step1 order=internal;
  class hloffer;
  model c21enprf = bacRatio hloffer / link=logit;
  where c21enprf ge 2;
  format c21enprf 1.;
  output out=HL_Bac predprobs=(I);
run;

data HL_Bac;
  set HL_Bac;
  from=input(_from_,1.);
  into=input(_into_,1.);
run;
ods select all;
proc freq data=HL_Bac;
  table from*into/nocol norow;
  format from into c21enprf.;
run;

