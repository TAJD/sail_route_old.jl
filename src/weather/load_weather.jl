using PyCall
unshift!(PyVector(pyimport("sys")["path"]), ENV["HOME"]*"/sail_route/src/weather/")

@pyimport load_weather as lw
