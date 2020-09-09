#!/bin/bash

icmcl_file_short=/work/bb0519/foci_input2/OPENIFS43R3-TCO95/2008010100/ICMCLhagwINIT
icmcl_year=2008

outfiles=" "
for (( yshift=-29 ; yshift<=9 ; yshift++ ))
do 
   
   year=$(( ${icmcl_year} + ${yshift} )) 
   out=icmcl_${icmcl_year}_${year}
   echo " cdo shifttime by ${yshift} years, year $year "
   
   if [[ "$(($year % 100))" -ne "0" ]] && [[ "$(($year % 4))" -eq "0" ]] 
   then 
      echo " $year leap year "
      del29feb=""
   else 
      echo " $year not leap year "
      del29feb="-del29feb"
   fi 
   echo " del29feb: $del29feb"
   
   cdo -O $del29feb -select,startdate=${year}-01-01T00:00:00,enddate=${year}-12-31T23:00:00 -shifttime,${yshift}years ${icmcl_file_short} ${out}
   outfiles=" $outfiles $out " 

done

echo $outfiles
export SKIP_SAME_TIME=1
cdo -O -mergetime $outfiles ICMCLhagwINIT_1979-2017
