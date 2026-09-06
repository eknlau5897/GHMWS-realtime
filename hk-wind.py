import pandas as pd
import xarray as xr
from herbie import Herbie
from herbie.toolbox import EasyMap, pc
from herbie import paint
import numpy as np
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import mpl_toolkits
from herbie.models.hafs import Storms
import scipy.ndimage
import cfgrib
import matplotlib.tri as tri
import scipy
from scipy.interpolate import griddata

url="https://data.weather.gov.hk/weatherAPI/hko_data/regional-weather/latest_10min_wind.csv"
data=pd.read_csv(url,on_bad_lines='skip')

data.to_xarray()

latitude=[22.2889,22.309,22.2011,22.2108,22.285,22.2142,22.3097,22.3119,22.2261,22.4689,22.2586,22.2944,22.2911,22.3756,22.3458,22.4025,22.4361,22.1975,22.2931,22.5286,22.4753,22.4397,22.4714,22.3578,22.3158,22.3467,22.3906,22.1822,22.4667,22.2478]#,22.2634]
longitude=[114.1558,113.922,114.0267,114.0292,114.1128,114.2186,114.2133,114.1728,114.1086,113.9836,113.9128,114.1997,114.0433,114.2744,113.8911,114.21,114.0847,114.2119,114.1686,114.1567,114.2375,114.1839,114.3606,114.2178,114.2556,114.0864,113.9767,114.3033,114.0089,114.1736]#,114.2998]
wind=data['10-Minute Mean Speed(km/hour)'][0:]
longitude=np.delete(longitude,np.where(np.isnan(wind)))
latitude=np.delete(latitude,np.where(np.isnan(wind)))
wind=np.delete(wind,np.where(np.isnan(wind)))
xi=np.arange(113.83,114.43,0.025)
yi=np.arange(22.14,22.57,0.025)
zi = griddata((longitude,latitude), wind, (xi[None,:], yi[:,None]),'nearest')
X,Y=np.meshgrid(xi,yi)

from scipy.ndimage import gaussian_filter
lat=scipy.ndimage.zoom(Y,10,order=1)
lon=scipy.ndimage.zoom(X,10,order=1)
wind_new=scipy.ndimage.zoom(zi,10,order=1)
wind_new=scipy.ndimage.gaussian_filter(wind_new,2)
percent_41=(wind_new>=41).mean()
percent_63=(wind_new>=63).mean()
percent_88=(wind_new>=88).mean()
percent_118=(wind_new>=118).mean()

import matplotlib.font_manager
from matplotlib.colors import Normalize
matplotlib.rcParams['font.family'] = ['PingFang HK']
fig = plt.figure(figsize=(12,12))
ax=plt.axes(projection=ccrs.PlateCarree())
p= ax.contourf(lon,lat,wind_new,
    levels=np.arange(0,185),
    transform=ccrs.PlateCarree(),
    cmap="gist_ncar",
)

q=ax.scatter(longitude,latitude,wind,color='k',
    transform=ccrs.PlateCarree()
)
y=plt.colorbar(
     p, ax=ax, orientation="horizontal", pad=0.05)
y.set_label('km/h(colour)',size='x-large')
for i, txt in enumerate(np.array(wind)):
    ax.annotate(f'{txt}', (longitude[i]+0.005, latitude[i]),color='w',size=10)
ax.set_title(f"香港時間:{int(data['Date time'][0])} HKT,\n天文台此刻已知所有站點既最高10min平均風速：{abs(np.max(wind))}km/h\n10分鐘平均風分佈圖(試驗產品）\n強風或以上覆蓋百分比:大概{float(percent_41)*100}%\n烈風或以上覆蓋百分比:大概{float(percent_63)*100}%\n暴風或以上覆蓋百分比:大概{float(percent_88)*100}%\n颶風或以上覆蓋百分比：大概{float(percent_118)*100}%\n全圖總平均風速：{float(np.mean(wind_new))}km/h\nPlotted by HKMETC",
    loc="left",color='k',fontweight='bold',size=16
)
gl=ax.gridlines(draw_labels=True)
gl.xlabels_bottom = True
gl.ylabels_left = True
ax.add_feature(cfeature.STATES.with_scale('10m'), edgecolor='red', linewidth=1,transform=pc)
ax.add_feature(cfeature.BORDERS.with_scale('10m'), linewidth=1,edgecolor='red',transform=pc)
ax.add_feature(cfeature.COASTLINE.with_scale('10m'), linewidth=1,edgecolor='red',transform=pc)
ax.add_feature(cfeature.LAND.with_scale('10m'),facecolor='white',edgecolor='k',transform=pc)
ax.set_extent([113.83,114.43,22.14,22.56])
plt.savefig("/Users/eknlau/VS_code/GHMWS-realtime/HK/wind.png",dpi=300,bbox_inches='tight')