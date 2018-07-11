using PyCall
pushfirst!(PyVector(pyimport("sys")["path"]), "")

"""
    haversine(lon1, lat1, lon2, lat2)

Calculate the haversine distance and bearing
"""
function haversine(lon1, lat1, lon2, lat2)
    R = 6372.8  # Earth radius in kilometers

    dLat = deg2rad(lat2 - lat1)
    dLon = deg2rad(lon2 - lon1)
    lat1 = deg2rad(lat1)
    lat2 = deg2rad(lat2)
    lon1 = deg2rad(lon1)
    lon2 = deg2rad(lon2)
    a = sin(dLat/2)^2 + cos(lat1)*cos(lat2)*sin(dLon/2)^2
    c = 2*asin(sqrt(a))
    theta = atan2(sin(dLon)*cos(lat2),
                  cos(lat1)*sin(lat2)-sin(lat1)*cos(lat2)*cos(dLon))
    theta = (rad2deg(theta) + 360) % 360
    return R*c*0.5399565, theta
end
