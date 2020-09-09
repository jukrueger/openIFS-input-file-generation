import numpy as np
import scipy as sp
from scipy.stats import gaussian_kde
import numpy.matlib 
import math
from scipy import signal
import xarray as xr
import pandas as pd
import matplotlib.pyplot as plt
import cartopy.crs as ccrs

# AMIP 1.1.6 (1870-2018)
tos_in='/work/bb0519/b350090/cmip_forcing/amip/tos_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-6_gn_187001-201812.nc'
sic_in='/work/bb0519/b350090/cmip_forcing/amip/siconc_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-6_gn_187001-201812.nc'

tos_out='/work/bb0519/b350090/cmip_forcing/amip_daily/tos_AMIP-1-1-6_daily.nc'
sic_out='/work/bb0519/b350090/cmip_forcing/amip_daily/sic_AMIP-1-1-6_daily.nc'

lclimatology = False

# Load data
ds_tos = xr.open_dataset(tos_in, decode_times=False)
ds_sic = xr.open_dataset(sic_in, decode_times=False)

# regain original time coordinates
ds_tos['time'] = xr.decode_cf(ds_tos, use_cftime=True).time
ds_sic['time'] = xr.decode_cf(ds_sic, use_cftime=True).time
print(ds_tos['tos'])
print(ds_sic['siconc'])

# Pick Kiel (lat = 54.5, lon = 10.5) and compute monthly timeseries 
ds_tos_Kiel = ds_tos.sel(lon = slice(10.5, 10.5), lat = slice(54.5,54.5))
ds_tos_Kiel['tos'][0:24].plot()
plt.gcf().savefig('kiel_tos_monthly.png',format='png')

if lclimatology:
   # Extend the timeseries by putting the December before January and the January after December
   ds_tos_Dec = ds_tos.isel(time=slice(11,12))
   ds_tos_Jan = ds_tos.isel(time=slice(0,1))
   ds_tos_extend = xr.concat([ds_tos_Dec['tos'], ds_tos['tos'],ds_tos_Jan['tos']], dim='time')
   
   # Extend time coordinate 
   times = ['2000-12-16 12:00:00','2001-01-16 12:00:00','2001-02-15 00:00:00','2001-03-16 12:00:00','2001-04-16 00:00:00','2001-05-16 12:00:00','2001-06-16 00:00:00','2001-07-16 12:00:00','2001-08-16 12:00:00','2001-09-16 00:00:00','2001-10-16 12:00:00','2001-11-16 00:00:00','2001-12-16 12:00:00','2002-01-16 12:00:00']
   time_da = xr.DataArray(times, [('time', times)])
   print(ds_tos_extend.time)
   ds_tos_extended = ds_tos_extend.assign_coords(time = time_da)
   print(ds_tos_extended.time)
   
   ds_tos_14months = xr.Dataset({"tos":(('time','lat','lon'), ds_tos_extended)}, 
                                coords={'time': pd.to_datetime(ds_tos_extended.time), 'lat': ds_tos_extended.lat, 'lon':ds_tos_extended.lon})
   
# Make it daily
ds_tos_daily = ds_tos['tos'].resample(time="1D").interpolate("linear")
ds_sic_daily = ds_sic['siconc'].resample(time="1D").interpolate("linear")

if lclimatology:
   # Drop 16.-31. Dec of previous year and 1.-16. Jan of following year to obtain 365 values
   ds_tos_daily_365 =  ds_tos_daily[16:-16,:,:]
   ds_tos_Kiel_365_daily = ds_tos_daily_365.sel(lon = slice(10.5, 10.5), lat = slice(54.5,54.5))
   ds_tos_Kiel_365_daily['tos'][0:730].plot()
   print(ds_tos_daily_365.shape)

ds_tos_Kiel_daily = ds_tos_daily.sel(lon = slice(10.5, 10.5), lat = slice(54.5,54.5))
ds_tos_Kiel_daily[0:730].plot()
plt.gcf().savefig('kiel_tos_daily.png',format='png')

ds_tos_daily.to_netcdf(tos_out)
ds_sic_daily.to_netcdf(sic_out)

plt.show()
