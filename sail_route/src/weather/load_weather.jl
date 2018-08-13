using PyCall

@pyimport importlib.machinery as machinery
loader = machinery.SourceFileLoader("weather",ENV["HOME"]*"/sail_route.jl/sail_route/src/weather/load_weather.py")
w = loader[:load_module]("weather")

function sample_weather()
    wisp, widi, cusp, cudi = w[:sample_weather_scenario]()
    return wisp, widi, cusp, cudi
end
