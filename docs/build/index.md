
<a id='sail_route-documentation-1'></a>

# sail_route documentation



<a id='sail_route.awa-Tuple{Any,Any,Any}' href='#sail_route.awa-Tuple{Any,Any,Any}'>#</a>
**`sail_route.awa`** &mdash; *Method*.



```
awa(twa, v_s, v_t)
```

Calculate the apparent wind angle given true wind angle, boat speed and wind speed.

**Example**

```julia
using sail_route
c_awa = sail_route.awa(60, 3.086, 5.144)
isapprox(0.6669807044553968, c_awa, rtol=3)

# output

true
```


<a target='_blank' href='https://github.com/TAJD/sail_route.jl/blob/84890d5889a3bb7b86277789c8bb79a13d637a4c/src/performance/aerodynamics.jl#L3-L19' class='documenter-source'>source</a><br>

