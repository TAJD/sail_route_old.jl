using PyCall, Interpolations

@pyimport importlib.machinery as machinery
loader = machinery.SourceFileLoader("weather",ENV["HOME"]*"/sail_route_old/src/weather/load_weather.py")
w = loader[:load_module]("weather")

"Generate known weather conditions"
function sample_weather()
    wisp, widi, cusp, cudi, wahi, wadi = w[:sample_weather_scenario]()
    return wisp, widi, cusp, cudi, wahi, wadi
end

function load_dataset(path_nc, var)
    ds_var = w[:load_dataset](path_nc, var)
    return ds_var
end


"Return the wave height and direction and the wind speed and direction from an ERA5 weather file."
function process_era5_weather(path_nc, longs, lats)
    rg_wisp, rg_widi, rg_wh, rg_wd, rg_wp = w[:process_era5_weather](path_nc, longs, lats)
    return rg_wisp, rg_widi, rg_wh, rg_wd, rg_wp
end


function load_era5_weather(path_nc)
    wisp, widi, wh, wd, wp = w[:retrieve_era5_weather](path_nc)
    return wisp, widi, wh, wd, wp
end


"""Regrids the weather data to a grid which is approximately the same as the sailing domain."""
function regrid_data(ds, longs, lats)
    dataset = w[:regrid_data](ds, longs, lats)
    return Array{Float64}(dataset[:values])
    # return dataset
end


"""Regrids the weather data to a grid which is the same as the sailing domain."""
function regrid_domain(ds, req_lons, req_lats)
    values, lons, lats = w[:return_data](ds)
    req_lons = mod.(req_lons .+ 360.0, 360.0) 
    interp_values = zeros((size(values)[1], size(req_lons)[1], size(req_lons)[2]))
    knots = (lats[end:-1:1], lons)
    for i in 1:size(values)[1]
        itp = interpolate(knots, values[i, end:-1:1, :], Gridded(Linear()))
        interp_values[i, end:-1:1, :] = itp.(req_lats, req_lons)
    end
    return interp_values
end

function load_cluster(path_nc, longs, lats, var)
    ds = w[:load_cluster](path_nc, longs, lats, var)
    return ds
end


function load_era20_weather(path_nc)
    wisp, widi, wh, wd, wp, time_values = w[:retrieve_era20_weather](path_nc)
    time = [Dates.unix2datetime(Int64(i)) for i in time_values]
    return wisp, widi, wh, wd, wp, time
end

