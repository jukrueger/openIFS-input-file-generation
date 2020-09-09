#!/bin/bash

# We need CDO 1.9.9, currently only available on Mistral
# Only this version can interpolate from regular grid to reduced octahedral Gaussian grid
cdo="/home/mpim/m214003/local/bin/cdo"

# We will need GRIB binaries to set metadata for variables
grib_bin="/sw/rhel6-x64/grib_api/grib_api-1.15.0-intel14/bin/"

icmcl_file=/work/bb0519/b350090/cmip_forcing/scripts/ICMCLhagwINIT_1979-2017
forcing_file_tos=/work/bb0519/b350090/cmip_forcing/amip_daily/tos_AMIP-1-1-6_daily.nc 
forcing_file_sic=/work/bb0519/b350090/cmip_forcing/amip_daily/sic_AMIP-1-1-6_daily.nc 
convert_var_tos_file=param_tos.txt 
convert_var_sic_file=param_sic.txt 
convert_ifsgrid_file=${icmcl_file}
icmcl_out=/work/bb0519/b350090/cmip_forcing/amip_daily/ICMCLhagwINIT_AMIP-1-1-6_19790101_20171231 

# Select AMIP period 1979-2018
select_time="-select,startdate=1979-01-01T00:00:00,enddate=2017-12-31T23:00:00"

# Convert files to grib and select time
echo " Convert from netCDF to GRIB1. ${select_time}"
$cdo -a -f grb -copy ${select_time} $forcing_file_tos forcing_file_tos.grb 
$cdo -a -f grb -copy ${select_time} $forcing_file_sic forcing_file_sic.grb 

# Remap to OpenIFS grid (only works with CDO 1.9.9rc5 on Mistral)
echo " Remap to grid in ${convert_ifsgrid_file} "
$cdo remapdis,$convert_ifsgrid_file forcing_file_tos.grb forcing_file_tos_ifsgrid.grb 
$cdo remapdis,$convert_ifsgrid_file forcing_file_sic.grb forcing_file_sic_ifsgrid.grb 
rm -rf forcing_file_tos.grb forcing_file_sic.grb 

# Convert to correct units
echo " Convert from Celsius to Kelvin and sea ice percent to sea ice fraction " 
$cdo -expr,'var1=var1+273.15' forcing_file_tos_ifsgrid.grb forcing_file_tos_ifsgrid_K.grb
# Also set values in range [-inf,0] to 0 to make sure we dont have negative sea ice values
$cdo -expr,'var1=var1/100' -setrtoc,-inf,0.,0. forcing_file_sic_ifsgrid.grb forcing_file_sic_ifsgrid_frac.grb 
rm -f forcing_file_tos_ifsgrid.grb forcing_file_sic_ifsgrid.grb 

# Set correct parameter table number
#echo " Set parameter table " 
#$cdo setpartabn,$convert_var_tos_file forcing_file_tos_ifsgrid_K.grb var_tos_ifsgrid.grb    
#$cdo setpartabn,$convert_var_sic_file forcing_file_sic_ifsgrid_frac.grb var_sic_ifsgrid.grb 
# Set correct leveltype for stl1
#${grib_bin}grib_set -s typeOfLevel=depthBelowLandLayer,level=0 var_tos_ifsgrid.grb var_tos_ifsgrid_level.grb
#exit

# Set correct headers for GRIB file
# We have to set centre to ECMWF, GRIB table version etc
# Seems like cdo setpartabn is not up to the task for this...
# You can use grib_compare to figure out what the differences are between two GRIB files
echo " Set GRIB headers for tos to stl1 "
grib_set_tos="hour=12,unitOfTimeRange=1,typeOfLevel=depthBelowLandLayer,level=0,generatingProcessIdentifier=255,centre=ecmf,topLevel=0,bottomLevel=7,P1=0,P2=0,tabl\
e2Version=128,indicatorOfParameter=139"
${grib_bin}/grib_set -s ${grib_set_tos} forcing_file_tos_ifsgrid_K.grb forcing_file_tos_ifsgrid_stl1.grb

grib_set_sic="hour=12,unitOfTimeRange=1,generatingProcessIdentifier=255,centre=ecmf,P1=0,P2=0,table2Version=128,indicatorOfParameter=31"
echo " Set GRIB headers for siconc to ci "
grib_set -s ${grib_set_sic} forcing_file_sic_ifsgrid_frac.grb forcing_file_sic_ifsgrid_ci.grb
rm -f forcing_file_tos_ifsgrid_K.grb forcing_file_sic_ifsgrid_frac.grb 

# Replace stl1 (skin temp) and ci (sea-ice conc) in ICMCL file with stuff from new files
echo " Replace stl1 and ci by new data "
$cdo -copy $select_time $icmcl_file icmcl_file_cut
$cdo replace icmcl_file_cut forcing_file_tos_ifsgrid_stl1.grb icmcl_stl1_replace.grb 
$cdo replace icmcl_stl1_replace.grb forcing_file_sic_ifsgrid_ci.grb ${icmcl_out}
rm -f icmcl_stl1_replace.grb forcing_file_sic_ifsgrid_ci.grb forcing_file_tos_ifsgrid_stl1.grb

echo " Calculate diffs between old file and new file to check that something happened "
$cdo -R -t ecmwf -f nc -sub ${icmcl_out} icmcl_file_cut diff.nc 
rm -f icmcl_file_cut 