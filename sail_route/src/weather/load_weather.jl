using PyCall

@pyimport importlib.machinery as machinery
loader = machinery.SourceFileLoader("weather",ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.py")
w = loader[:load_module]("weather")

"Generate known weather conditions"
function sample_weather()
    wisp, widi, cusp, cudi, wahi, wadi = w[:sample_weather_scenario]()
    return wisp, widi, cusp, cudi, wahi, wadi
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


function regrid_data(ds, longs, lats)
    return w[:regrid_data](ds, longs, lats)
end

