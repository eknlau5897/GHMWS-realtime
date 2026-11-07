import os
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
from scipy.ndimage import gaussian_filter
import matplotlib.font_manager
from matplotlib.colors import Normalize

# ==============================================================================
# DATA FETCHING & PREPROCESSING
# ==============================================================================
url = "https://data.weather.gov.hk/weatherAPI/hko_data/regional-weather/latest_1min_temperature.csv"

data_df = pd.read_csv(url)
data = data_df.to_xarray()

latitude = [
    22.309, 22.201, 22.263, 22.2705, 22.302, 22.278, 22.3047, 22.3703,
    22.3119, 22.335, 22.3186, 22.4689, 22.2586, 22.4028, 22.2911, 22.3756,
    22.4025, 22.3358, 22.2817, 22.4361, 22.5019, 22.2142, 22.5286, 22.4835,
    22.4753, 22.4106, 22.4483, 22.3578, 22.2642, 22.3158, 22.3442, 22.3836,
    22.3756, 22.3858, 22.1822, 22.4667, 22.2478, 22.3394, 22.4408
]

longitude = [
    113.922, 114.0267, 114.2998, 114.1836, 114.1743, 114.162, 114.2172,
    114.3125, 114.1728, 114.1847, 114.2247, 113.9836, 113.9128, 114.3231,
    114.0433, 114.2744, 114.21, 114.1369, 114.2361, 114.0847, 114.1111,
    114.2186, 114.1567, 114.1174, 114.2375, 114.1244, 114.1772, 114.2178,
    114.155, 114.2556, 114.11, 114.1078, 114.1267, 113.9642, 114.3033,
    114.0089, 114.1736, 114.2053, 114.0183
]

temp = np.array(data['Air Temperature(degree Celsius)'])
xi = np.arange(113.83, 114.43, 0.025)
yi = np.arange(22.14, 22.57, 0.025)

# Filter out NaNs
nan_mask = np.isnan(temp)
longitude = np.delete(longitude, np.where(nan_mask))
latitude = np.delete(latitude, np.where(nan_mask))
temp = np.delete(temp, np.where(nan_mask))

# Grid Interpolation
zi = griddata((longitude, latitude), temp, (xi[None, :], yi[:, None]), 'nearest')
X, Y = np.meshgrid(xi, yi)

lat = scipy.ndimage.zoom(Y, 10, order=1)
lon = scipy.ndimage.zoom(X, 10, order=1)
temperature = scipy.ndimage.zoom(zi, 10, order=1)
temperature = gaussian_filter(temperature, sigma=1)

# ==============================================================================
# FONT & MAP PLOTTING CONFIGURATION
# ==============================================================================
matplotlib.rcParams['font.sans-serif'] = [
    'PingFang HK', 'Heiti TC', 'Noto Sans CJK SC', 'DejaVu Sans', 'sans-serif'
]
matplotlib.rcParams['axes.unicode_minus'] = False

fig = plt.figure(figsize=(12, 12))
ax = plt.axes(projection=ccrs.PlateCarree())

p = ax.contourf(
    lon, lat, temperature,
    cmap='gist_ncar',
    levels=np.arange(-6, 45.1, 0.1),
    transform=ccrs.PlateCarree()
)

q = ax.scatter(
    longitude, latitude, temp,
    color='k',
    transform=ccrs.PlateCarree()
)

ax.add_feature(cfeature.STATES.with_scale('10m'), edgecolor='k', linewidth=1, transform=pc)
ax.add_feature(cfeature.BORDERS.with_scale('10m'), linewidth=1, edgecolor='k', transform=pc)
ax.add_feature(cfeature.COASTLINE.with_scale('10m'), linewidth=1, edgecolor='k', transform=pc)
ax.add_feature(cfeature.LAND.with_scale('10m'), facecolor='white', edgecolor='k', transform=pc)

y = plt.colorbar(
    p, ax=ax, orientation="horizontal", pad=0.05, cmap='nipy_spectral', extend='max'
)
y.set_label('degree Celsius(colour)', size='x-large')

for i, txt in enumerate(temp):
    ax.annotate(str(txt), (longitude[i], latitude[i]), color='w')

# Extract baseline data safely from raw dataset
date_time_val = int(data['Date time'].values[0])
max_temp_val = float(np.max(data['Air Temperature(degree Celsius)'].values))
hko_temp_val = float(data['Air Temperature(degree Celsius)'].values[4])

title_left = (
    f"香港時間:{date_time_val} HKT\n"
    f"天文台此刻所有站點既最高溫：{max_temp_val}degree Celsius\n"
    f"天文台溫度：{hko_temp_val} degree Celsius\n"
    f"氣溫分佈圖(試驗產品）\n"
    f"Plotted by HKMETC"
)

ax.set_title(title_left, loc="left", color='k', fontweight='bold', size=16)
ax.set_title("站點data from HKO 開放數據集", loc="right", size=16)

gl = ax.gridlines(draw_labels=True)
gl.xlabels_bottom = True
gl.ylabels_left = True

ax.set_extent([113.83, 114.4, 22.16, 22.57])

# ==============================================================================
# SAVE OUTPUT
# ==============================================================================
output_dir = "HK"
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "temp.png")

plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"✅ Temperature distribution plot generated and saved to {output_path}")