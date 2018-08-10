
"""Convert hours in float to hours and minutes."""
function convert_time(old_time::Float64)
    h = floor(old_time)
    m = floor((old_time - h)*60)
    return Dates.Hour(h)+Dates.Minute(m)
end


function route_solve(lon1, lon2, lat1, lat2, x_nodes, y_nodes, y_dist, wisp, widi, cusp, cudi, polar, start)
    x, y, land = co_ordinates(lon1, lon2, lat1, lat2, x_nodes, y_nodes, y_dist)
    empty = zeros(x)
    earliest_times = fill!(empty, Inf)
    prev_node = zeros(x)
    node_indices = reshape(1:length(x), size(x)) 
    arrival_time = Inf
    @simd for idx in 1:size(x)[2]
        @inbounds d, b = haversine(lon1, lat1, x[1, idx], y[1, idx])
        ws_int = wisp[:interp](time=start, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        wd_int = widi[:interp](time=start, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        cs_int = cusp[:interp](time=start, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        cd_int = cudi[:interp](time=start, lon_b=x[1, idx], lat_b=y[1, idx])[:data][1]
        @inbounds earliest_times[1, idx] = d/correct_speed(polar, cd_int, cs_int, wd_int, ws_int, b)
    end
    
    for idy in 1:size(x)[1]-1
        @simd for idx in 1:size(x)[2]
            t = start + convert_time(earliest_times[idy, idx])
            @inbounds d, b = haversine(x[idy, idx], y[idy, idx], x[idy+1, idx], y[idy+1, idx])
            ws_int = wisp[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            wd_int = widi[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            cs_int = cusp[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            cd_int = cudi[:interp](time=t, lon_b=x[idy, idx], lat_b=y[idy, idx])[:data][1]
            @inbounds tt = earliest_times[idy, idx] + d/correct_speed(polar, cd_int, cs_int, wd_int, ws_int, b)
            if earliest_times[idy+1, idx] > tt
                earliest_times[idy+1, idx] = tt
            end
        end
    end
    
    for idx in 1:size(x)[2]
        @inbounds d, b = haversine(x[end, idx], y[end, idx], lon2, lat2)
        t = start + convert_time(earliest_times[end, idx])
         ws_int = wisp[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         wd_int = widi[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         cs_int = cusp[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
         cd_int = cudi[:interp](time=t, lon_b=x[end, idx], lat_b=y[end, idx])[:data][1]
        @inbounds tt = earliest_times[end, idx] + d/correct_speed(polar, cd_int, cs_int, wd_int, ws_int, b)
        if arrival_time > tt
            arrival_time = tt
        end
    end    
    return arrival_time, earliest_times
end


