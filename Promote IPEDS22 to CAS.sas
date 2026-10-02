libname IPEDS23 '~/IPEDS23';
options fmtsearch=(IPEDS23);

proc casutil;
    droptable casdata="ipeds22Data" incaslib="casuser";
    load data=ipeds23.ipeds22data
         outcaslib="casuser" 
         casout="ipeds22Data" 
         replace;
    promote casdata="ipeds22Data" incaslib="casuser";
run;
quit;  