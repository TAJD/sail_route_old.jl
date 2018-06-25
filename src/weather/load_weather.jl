using PyCall

@pyimport numpy as np
@pyimport xarray as xr

println(xr.DataArray([[2, 3, 4], [5, 6, 7]]))
