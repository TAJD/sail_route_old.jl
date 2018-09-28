using Distributed
@everywhere using SharedArrays, BenchmarkTools


@everywhere function myrange(q::SharedArray) # create a custom iterator which breaks up a range based on the processor number
    @show idx = indexpids(q)
    if idx == 0 # This worker is not assigned a piece
        return 1:0, 1:0
    end
    nchunks = length(procs(q))
    splits = [round(Int, s) for s in range(0, stop=size(q,2), length=nchunks+1)]
    1:size(q,1), splits[idx]+1:splits[idx+1]
end


@everywhere function advection_chunk!(q, u, irange, jrange, trange)
    # @show (irange, jrange, trange)  # display so we can see what's happening
    for t in trange, j in jrange, i in irange
        q[i,j,t+1] = q[i,j,t] + u[i,j,t]
    end
    q
end


@everywhere advection_shared_chunk!(q, u) = advection_chunk!(q, u, myrange(q)..., 1:size(q,3)-1) # myrange returns two arguments, could be what the dots are for?

advection_serial!(q, u) = advection_chunk!(q, u, 1:size(q,1), 1:size(q,2), 1:size(q,3)-1)

function advection_parallel!(q, u)
    for t = 1:size(q,3)-1
        @sync @distributed for j = 1:size(q,2)
            for i = 1:size(q,1)
                q[i,j,t+1]= q[i,j,t] + u[i,j,t]
            end
        end
    end
    q
end


function advection_shared!(q, u)
    @sync begin
        for p in procs(q)
            @async remotecall_wait(advection_shared_chunk!, p, q, u)
        end
    end
    q
end


q = SharedArray{Float64,3}((500,500,500))
u = SharedArray{Float64,3}((500,500,500))

println("Advection serial")
serial = @benchmark advection_serial!(q, u)
dump(serial)

println("Advection parallel")
parallel = @benchmark advection_parallel!(q, u)
dump(parallel)

println("Advection shared")
shared = @benchmark advection_shared!(q, u)
dump(shared)