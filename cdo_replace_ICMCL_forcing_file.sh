#!/bin/bash 

# Example of how to convert two new forcing files to GRIB file format and to reduced octahedral grid and replace two variables of an original forcing file by the variables stored in the two new forcing files

icmcl_file=/path/to/icmcl_file                                                                                                                   # original forcing file
forcing_file_1=/path/to/forcing_file_1.nc													 # Load new .nc forcing file
forcing_file_2=/path/to/forcing_file_2.nc    												 	 # Load new .nc forcing file     
convert_var_1_file=/path/to/param_1.txt                                                                                                		 # parameter table for changing the name of variable 1 to the same name provided in original forcing file 
convert_var_2_file=/path/to/param_2.txt                                                                                          		 # parameter table for changing the name of variable 2 to the same name provided in original forcing file
convert_ifsgrid_file=/path/to/ICMGGECE3INIT

cdo -f grb copy $forcing_file_1 forcing_file_1.grb 											 	 # convert new forcing file  into .grb format 
cdo -f grb copy $forcing_file_2 forcing_file_2.grb												 # convert new forcing file  into .grb format
/home/mpim/m214003/local/bin/cdo remapdis,$convert_ifsgrid_file forcing_file_1.grb forcing_file_1_ifsgrid.grb					 # convert new forcing file into reduced octahedral grid with prerelease of cdo version 1.9.9,only available on mistral so far!
/home/mpim/m214003/local/bin/cdo remapdis,$convert_ifsgrid_file forcing_file_2.grb forcing_file_2_ifsgrid.grb					 # convert new forcing file into reduced octahedral grid with prerelease of cdo version 1.9.9,only available on mistral so far!	
cdo setpartabn,$convert_var_tos_file forcing_file_1_ifsgrid.grb var_1_ifs_grid.grb   				                                 # change variable name in new forcing file from 'var1' to the variable name that should be replaced, check cdo showname
cdo setpartabn,$convert_var_siconc_file forcing_file_2_ifsgrid.grb var2_ifsgrid.grb                                                              # change variable name in new forcing file from 'var1' to the variable name that should be replaced check cdo showname
cdo shifttime,-7years $icmcl_file icmcl_shifted_7yrs.grb                                                                                         # shift time axis in original forcing file from 2008 to 2001 (avoid a leap year)  
cdo del29feb icmcl_shifted_7yrs.grb icmcl_shifted_7yrs_del29feb.grb                                                                              # delete Feb 29th in original forcing file 
cdo delete,year=2002,month=1,day=1,2,3,4,5,6 icmcl_shifted_7yrs_del29feb.grb icmcl_shifted_7yrs_del29feb_365.grb                                 # delete first 6 days of year 2002 in original file to obtain the same time axis length between original and new forcing file  
cdo replace icmcl_shifted_7yrs_del29feb_365.grb var1_ifsgrid.grb  icmcl_var1_replace                                                             # replace variable 1  in the original file by the variable 1 stored in the new forcing file
cdo replace icmcl_var1_replace.grb var2_ifsgrid.grb icmcl_var1_replace_var2_replace                                                              # replace variable 2  in the original file by the variable 2 stored in the new forcing file     
cdo -a -copy  icmcl_var1_replace_var2_replace icmcl_var1_replace_var2_replace_absolute_time                     	                         # convert time axis from relative to absolute  
