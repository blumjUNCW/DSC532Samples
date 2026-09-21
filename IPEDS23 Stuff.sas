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

proc format lib=ipeds23 cntlout=IPEDS23Formats;
run;

proc contents data=step1 varnum;
run;
