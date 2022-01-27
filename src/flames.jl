function null(p::T, tid) where T
end

function sinusoidal(p::T, tid) where T
    sin.(p[tid, :])
end

function polar(p::T, tid; theta = 0) where T
    r = sqrt(sum(p[tid,1]*p[tid,1] + p[tid,2]*p[tid,2]))
    theta = atan(p[tid,1], p[tid,2]) + theta

    p[tid,2] = theta/pi
    p[tid,2] = r-1
end

function horseshoe(p::T, tid) where T
    r = sqrt(p[tid,1]*p[tid,1] + p[tid,2]*p[tid,2])
    if r < 0.001
        r = 0.001
    end

    v1 = (p[tid,1]-p[tid,2])*(p[tid,1]+p[tid,2])/r
    v2 = 2*p[tid,1]*p[tid,2]/r

    p[tid,1] = v1
    p[tid,2] = v2
end

function heart(p::T, tid) where T
    r = sqrt(p[tid,1]*p[tid,1] + p[tid,2]*p[tid,2])
    theta = atan(p[tid,1], p[tid,2])

    p[tid,1] = r*sin(theta*r)
    p[tid,2] = -r*cos(theta*r)
end

function rotate(p::T, tid; theta = 0.5) where T

    r1 = p[tid,1]*sin(theta) - p[tid,2]*cos(theta)
    r2 = p[tid,1]*cos(theta) + p[tid,2]*sin(theta)

    p[tid,1] = r1
    p[tid,2] = r2
end

function swirl(p::T, tid) where T
    r = sqrt(p[tid,1]*p[tid,1] + p[tid,2]*p[tid,2])
    r1 = p[tid,1]*sin(r*r) - p[tid,2]*cos(r*r)
    r2 = p[tid,1]*cos(r*r) + p[tid,2]*sin(r*r)

    p[tid,1] = r1
    p[tid,1] = r2
end

function sierpinski(point::T, shape_vertex::T) where T
    return 0.5*(point .+ shape_vertex)
end
