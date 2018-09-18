"""Load weather files.

Reduce the amount of interpolating associated with large weather files.

Thomas Dickson
thomas.dickson@soton.ac.uk
25/05/2018
"""

import numpy as np
import pandas as pd
import xarray as xr
import xesmf as xe


def look_in_netcdf(path):
    """Load netcdf file and return xrray."""
    with xr.open_dataset(path) as ds:
        print(ds.keys())


def load_dataset(path_nc, var):
    """Load netcdf file and return a specific variable."""
    with xr.open_dataset(path_nc) as ds:
        ds.coords['lat'] = ('latitude', ds['latitude'].values)
        ds.coords['lon'] = ('longitude', ds['longitude'].values)
        ds.swap_dims({'longitude': 'lon', 'latitude': 'lat'})
        return ds[var]


def regrid_data(ds, longs, lats):
    """Regrid dataset to new longs and lats."""
    ds_out = xr.Dataset({'lat': (['lat_b'], lats),
                         'lon': (['lon_b'], longs)})
    regridder = xe.Regridder(ds, ds_out, 'patch', reuse_weights=True)
    ds0 = regridder(ds)
    ds0.coords['lat_b'] = ('lat_b', ds0['lat'].values)
    ds0.coords['lon_b'] = ('lon_b', ds0['lon'].values)
    return ds0


def load_cluster(path_nc, longs, lats, var):
    """Load cluster data."""
    with xr.open_dataset(path_nc) as ds:
            ds.coords['lat'] = ('latitude', ds['latitude'].values)
            ds.coords['lon'] = ('longitude', ds['longitude'].values)
            ds.swap_dims({'longitude': 'lon', 'latitude': 'lat'})
    x = xr.DataArray(longs, dims='lon')
    y = xr.DataArray(lats, dims='lat')
    ds = ds.to_array(var)
    return ds.interp(longitude=x, latitude=y)


def process_wind(path_nc, longs, lats):
    """
    Return wind speed and direction data.

    Data is regridded to the location of each node.
    """
    ds_u10 = load_dataset(path_nc, 'u10')
    regrid_ds_u10 = regrid_data(ds_u10, longs[:, 0], lats[0, :])
    ds_v10 = load_dataset(path_nc, 'v10')
    regrid_ds_v10 = regrid_data(ds_v10, longs[:, 0], lats[0, :])
    ws = 1.943844 * (regrid_ds_u10**2 + regrid_ds_v10**2)**0.5
    wind_dir = np.rad2deg(np.arctan2(regrid_ds_u10, regrid_ds_v10)) + 180.0
    return ws, wind_dir


def process_waves(path_nc, longs, lats):
    """Return wave data."""
    wh = load_dataset(path_nc, 'swh')
    wd = load_dataset(path_nc, 'mwd')
    wp = load_dataset(path_nc, 'mwp')
    regrid_wh = regrid_data(wh, longs[:, 0], lats[0, :])
    regrid_wd = regrid_data(wd, longs[:, 0], lats[0, :])
    regrid_wp = regrid_data(wp, longs[:, 0], lats[0, :])
    return regrid_wh, regrid_wd, regrid_wp


def process_era5_weather(path_nc, longs, lats):
    """Return era5 weather data."""
    wisp = load_dataset(path_nc, 'wind')
    widi = load_dataset(path_nc, 'dwi')
    wh = load_dataset(path_nc, 'swh')
    wd = load_dataset(path_nc, 'mdts')
    wp = load_dataset(path_nc, 'mpts')
    rg_wisp = regrid_data(wisp, longs[:, 0], lats[0, :])
    rg_widi = regrid_data(widi, longs[:, 0], lats[0, :])
    rg_wh = regrid_data(wh, longs[:, 0], lats[0, :])
    rg_wd = regrid_data(wd, longs[:, 0], lats[0, :])
    rg_wp = regrid_data(wp, longs[:, 0], lats[0, :])
    return rg_wisp, rg_widi, rg_wh, rg_wd, rg_wp


def retrieve_era5_weather(path_nc):
    wisp = load_dataset(path_nc, 'wind')
    widi = load_dataset(path_nc, 'dwi')
    wh = load_dataset(path_nc, 'swh')
    wd = load_dataset(path_nc, 'mdts')
    wp = load_dataset(path_nc, 'mpts')
    return wisp, widi, wh, wd, wp


def change_area_values(array, value, lon1, lat1, lon2, lat2):
    """
    Change the weather values in a given rectangular area.

    array is an xarray DataArray
    value is the new value
    lon1 and lat1 are the coordinates of the bottom left corner of the area
    lon2 and lat2 are the coordinates of the top right of the area
    """
    lc = array.coords['lon']
    la = array.coords['lat']
    array.loc[dict(lon_b=lc[(lc > lon1) & (lc < lon2)],
                   lat_b=la[(la > lat1) & (la < lat2)])] = value
    return array


def sample_weather_scenario():
    """
    Generate a weather scenario with known values for the wind condition.
    """
    times = pd.date_range('1/1/2000', periods=72, freq='6H')
    latitude = np.linspace(0, 10, 11)
    longitude = np.linspace(0, 10, 11)
    wsp_vals = np.full((72, 11, 11), 10.0)
    wdi_vals = np.full((72, 11, 11), 0.0)
    cusp_vals = np.full((72, 11, 11), 0.0)
    cudi_vals = np.full((72, 11, 11), 0.0)
    wadi_vals = np.full((72, 11, 11), 0.0)
    wahi_vals = np.full((72, 11, 11), 0.0)
    wisp = xr.DataArray(wsp_vals, dims=['time', 'lon_b', 'lat_b'],
                        coords={'time': times,
                                'lon_b': longitude,
                                'lat_b': latitude})
    widi = xr.DataArray(wdi_vals, dims=['time', 'lon_b', 'lat_b'],
                        coords={'time': times,
                                'lon_b': longitude,
                                'lat_b': latitude})
    cusp = xr.DataArray(cusp_vals, dims=['time', 'lon_b', 'lat_b'],
                        coords={'time': times,
                                'lon_b': longitude,
                                'lat_b': latitude})
    cudi = xr.DataArray(cudi_vals, dims=['time', 'lon_b', 'lat_b'],
                        coords={'time': times,
                                'lon_b': longitude,
                                'lat_b': latitude})
    wahi = xr.DataArray(cusp_vals, dims=['time', 'lon_b', 'lat_b'],
                        coords={'time': times,
                                'lon_b': longitude,
                                'lat_b': latitude})
    wadi = xr.DataArray(cudi_vals, dims=['time', 'lon_b', 'lat_b'],
                        coords={'time': times,
                                'lon_b': longitude,
                                'lat_b': latitude})
    return wisp, widi, cusp, cudi, wahi, wadi


if __name__ == '__main__':
    path = "/mainfs/home/td7g11/weather_data/transat_weather/2016_march.nc"
    look_in_netcdf(path)
    rg_wisp, rg_widi, rg_wh, rg_wd, rg_wp = retrieve_era5_weather(path)
    print(rg_wisp['number'])
    print(rg_wisp['longitude'])
    print(rg_wisp['latitude'])
    print(rg_wisp['time'])
    print(rg_wisp.interp(longitude=-16.9, latitude=57.24, number=1, method="nearest"))