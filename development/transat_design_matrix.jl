include(ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/domain.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/route/shortest_path.jl")
include(ENV["HOME"]*"/sail_route.jl/sail_route/src/performance/polar.jl")

using PyCall
@pyimport xarray


function load_data()
    maribot_data = ENV["HOME"]*"/pyroute/analysis/asv_transat/maribot_vane.csv"

    boat_performance = ENV["HOME"]*"/sail_route.jl/sail_route/src/data/first40_orgi.csv"
    january_data = ENV["HOME"]*"/weather_data/transat_weather/2016_january.nc"
    february_data = ENV["HOME"]*"/weather_data/transat_weather/2016_february.nc"
    march_data = ENV["HOME"]*"/weather_data/transat_weather/2016_march.nc"
    april_data = ENV["HOME"]*"/weather_data/transat_weather/2016_april.nc"
    june_data = ENV["HOME"]*"/weather_data/transat_weather/2016_june.nc"
    july_data = ENV["HOME"]*"/weather_data/transat_weather/2016_july.nc"
    august_data = ENV["HOME"]*"/weather_data/transat_weather/2016_august.nc"
    september_data = ENV["HOME"]*"/weather_data/transat_weather/2016_september.nc"
    october_data = ENV["HOME"]*"/weather_data/transat_weather/2016_october.nc"
    november_data = ENV["HOME"]*"/weather_data/transat_weather/2016_november.nc"
    december_data = ENV["HOME"]*"/weather_data/transat_weather/2016_december.nc"

    path_names = [january_data, february_data, march_data, april_data, june_data, july_data, august_data, september_data, october_data, november_data, december_data]
    # arrays = [xarray.open_dataset(i) for i in path_names]
    # data = xarray[:merge](arrays)
    # data.to_netcdf(ENV["HOME"]*"/weather_data/transat_weather/2016.nc")
    # january_routing = xarray[:merge](arrays[1:3])
    # println(january_routing)
    # println(arrays[2])
    # january_routing = xarray[:merge](xarray.open_dataset(i) for i in path_names)
    println(jan_array)
    jan_array = xarray.open_dataset(january_data)
    feb_array = xarray.open_dataset(february_data)
    jan_array[:combine_first](feb_array)
    println(feb_array)
    println(jan_array)
end

load_data()