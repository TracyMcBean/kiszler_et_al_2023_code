import sys
import xarray as xr
import numpy as np

# Compute hourly accumulated precipitation for ICON simulation
# Call: python compute_1h_precip.py <meteogram>
# 
# 2021.04.08, TK
# 2021.07.27, TK: Added _CON values (for nwp necessary)
# Get data
meteogram = sys.argv[1]
ds = xr.open_dataset(meteogram)

rain = ds.RAIN_GSP.values + ds.RAIN_CON.values
snow = ds.SNOW_GSP.values + ds.SNOW_CON.values

precip = rain + snow 

precip_h = np.empty([24])
rain_h = np.empty([24])
snow_h = np.empty([24])
# compute hourly value. time step is 9 sec.
i = 0 
i_end = 0 
c = 0
while i_end+3600/9 < len(precip):
    i_end = int(i+3600/9)
    precip_h[c] = precip[i_end] - precip[i]
    rain_h[c] = rain[i_end] - rain[i]
    snow_h[c] = snow[i_end] - rain[i]
    i = i_end
    c += 1

# write into dummy file
tmp_nc = sys.argv[2]
tmp_ds = xr.open_dataset(tmp_nc)

tmp_ds.RAIN_CON.values = precip_h
tmp_ds.RAIN_GSP.values = rain_h
tmp_ds.SNOW_GSP.values = snow_h

tmp_ds.to_netcdf(tmp_nc, mode='w')
print(tmp_ds, tmp_ds.RAIN_GSP.values, tmp_ds.RAIN_CON.values, tmp_ds.SNOW_GSP.values)
print(rain_h,precip_h,snow_h)
