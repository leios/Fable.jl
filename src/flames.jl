function null(p::T, tid, t) where T
end

function sinusoidal(p::T, tid, t) where T
    p[tid,2] = sin(p[tid, 2])
    p[tid,1] = sin(p[tid, 1])
end

function polar_play(p::T, tid, t; theta = 2pi) where T
    r = sqrt(sum(p[tid,2]*p[tid,2] + p[tid,1]*p[tid,1]))
    theta = atan(p[tid,1], p[tid,2]) + theta*t

    p[tid,1] = 1-r
    p[tid,2] = theta/pi
end

function polar(p::T, tid, t; theta = 0) where T
    r = sqrt(sum(p[tid,2]*p[tid,2] + p[tid,1]*p[tid,1]))
    theta = atan(p[tid,1], p[tid,2]) + theta

    p[tid,1] = r-1
    p[tid,2] = theta/pi
end

function horseshoe(p::T, tid, t) where T
    r = sqrt(p[tid,2]*p[tid,2] + p[tid,1]*p[tid,1])
    if r < 0.001
        r = 0.001
    end

    x = (p[tid,2]-p[tid,1])*(p[tid,2]+p[tid,1])/r
    y = 2*p[tid,2]*p[tid,1]/r

    p[tid,1] = y
    p[tid,2] = x
end

function heart(p::T, tid, t; theta = 0) where T
    r = sqrt(p[tid,2]*p[tid,2] + p[tid,1]*p[tid,1])
    theta = atan(p[tid,1], p[tid,2]) + theta

    p[tid,1] = -r*cos(theta*r)
    p[tid,2] = r*sin(theta*r)
end

function rotate(p::T, tid, t; theta = 0.5) where T

    x = p[tid,2]*cos(theta) - p[tid,1]*sin(theta)
    y = p[tid,2]*sin(theta) + p[tid,1]*cos(theta)

    p[tid,1] = y
    p[tid,2] = x
end

function swirl(p::T, tid, t) where T
    r = sqrt(p[tid,1]*p[tid,1] + p[tid,2]*p[tid,2])

    y = p[tid,2]*cos(r*r) + p[tid,1]*sin(r*r)
    x = p[tid,2]*sin(r*r) - p[tid,1]*cos(r*r)

    p[tid,1] = y
    p[tid,2] = x
end

function sierpinski(point::T, shape_vertex::T) where T
    return 0.5*(point .+ shape_vertex)
end
