libname SASData '~/SASData';

proc hpforest data=sasdata.cdi ;
  target ba_bs / Level=interval;
  input land--hs_grad poverty--inc_tot / Level=interval;
  input region / Level=nominal;
  performance nthreads=12;
run;

proc forest data=sasdata.cdi rbaimp vii=3;
  target ba_bs / Level=interval;
  input land--hs_grad poverty--inc_tot / Level=interval;
  input region / Level=nominal;
run;