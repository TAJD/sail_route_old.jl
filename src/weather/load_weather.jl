using PyCall

unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport src.weather.load_weather as lw

function sample_weather()
    wind_speed, wind_dir = lw.sample_weather_scenario()
    return wind_speed, wind_dir
end
