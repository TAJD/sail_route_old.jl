export awa

"""
    awa(twa, v_s, v_t)

Calculate the apparent wind angle given true wind angle, boat speed and wind speed.

# Example

```jldoctest
using sail_route
c_awa = sail_route.awa(60, 3.086, 5.144)
isapprox(0.6669807044553968, c_awa, rtol=3)

# output

true
```
"""
function awa(twa::Float64, v_s::Float64, v_t::Float64)
    return atan(sind(twa)/(cosd(twa) + v_s/v_t))
end
