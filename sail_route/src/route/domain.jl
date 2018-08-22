using PyCall

@pyimport importlib.machinery as machinery
loader = machinery.SourceFileLoader("pydomain",ENV["HOME"]*"/sail_route.jl/sail_route/src/route/pydomain.py")
pd = loader[:load_module]("pydomain")

"""
    haversine(lon1, lat1, lon2, lat2)

Calculate the haversine distance and bearing. Distance is in nm.
"""
function haversine(lon1::Float64, lat1::Float64, lon2::Float64, lat2::Float64)
    R = 6372.8  # Earth radius in kilometers

    dLat = deg2rad(lat2 - lat1)
    dLon = deg2rad(lon2 - lon1)
    lat1 = deg2rad(lat1)
    lat2 = deg2rad(lat2)
    lon1 = deg2rad(lon1)
    lon2 = deg2rad(lon2)
    a = sin(dLat/2)^2 + cos(lat1)*cos(lat2)*sin(dLon/2)^2
    c = 2*asin(sqrt(a))
    theta = atan(sin(dLon)*cos(lat2),
                 cos(lat1)*sin(lat2)-sin(lat1)*cos(lat2)*cos(dLon))
    theta = (rad2deg(theta) + 360) % 360
    return R*c*0.5399565, theta
end

"""
    co_ordinates(start_long, finish_long, start_lat, finish_lat,
                 n_ranks, n_nodes, dist)

Return the co-ordinates of each point across the discretized domain.
"""
function co_ordinates(start_long, finish_long, start_lat, finish_lat,
                      n_ranks::Int, n_nodes::Int, dist)
    x, y, land = pd[:return_co_ords](start_long, finish_long, start_lat,
                                     finish_lat, n_ranks, n_nodes,
                                     dist)
    return x, y, land
end


function output()
    x, y, land = co_ordinates(-6.0, -14.0, 0.0, 0.0, 10, 10, 5000.0)
    print(x)
    print(y)
    print(land)
end


function min_angle(a::AbstractFloat, b::AbstractFloat)
    abs(mod(a - b + 180.0, 360.0) - 180.0)
end