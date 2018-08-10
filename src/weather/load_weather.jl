using PyCall

unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport src.weather.load_weather as lw

function sample_weather()
    wisp, widi, cusp, cudi = lw.sample_weather_scenario()
    return wisp, widi, cusp, cudi
end
