using PyCall
# unshift!(PyVector(pyimport("sys")["path"]), ENV["HOME"]*"/sail_route/src/weather/")

unshift!(PyVector(pyimport("sys")["path"]), "")

@pyimport src.weather.load_weather as lw
