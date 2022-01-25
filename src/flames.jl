function identity(p::T) where T
    return p
end

function sinusoidal(p::T) where T
    return sin.(p)
end

function polar(p::T) where T
    r = sqrt(sum(p[1]*p[1] + p[2]*p[2]))
    theta = atan(p[1], p[2])

    p[1] = theta/pi
    p[2] = r-1

    return p
end

function horseshoe(p::T) where T
    r = sqrt(p[1]*p[1] + p[2]*p[2])
    if r < 0.001
        r = 0.001
    end

    v1 = (p[1]-p[2])*(p[1]+p[2])/r
    v2 = 2*p[1]*p[2]/r

    p[1] = v1
    p[2] = v2
    return p
end

function heart(p::T) where T
    r = sqrt(p[1]*p[1] + p[2]*p[2])
    theta = atan(p[1], p[2])

    p[1] = r*sin(theta*r)
    p[2] = -r*cos(theta*r)

    return p
end

function rotate(p::T; theta = 0.5) where T

    r1 = p[1]*sin(theta) - p[2]*cos(theta)
    r2 = p[1]*cos(theta) + p[2]*sin(theta)

    p[1] = r1
    p[2] = r2

    return p
end

function swirl(p::T) where T
    r = sqrt(p[1]*p[1] + p[2]*p[2])
    r1 = p[1]*sin(r*r) - p[2]*cos(r*r)
    r2 = p[1]*cos(r*r) + p[2]*sin(r*r)

    p[1] = r1
    p[2] = r2

    return p
end

function sierpinski(point::T, shape_vertex::T) where T
    return 0.5*(point .+ shape_vertex)
end
