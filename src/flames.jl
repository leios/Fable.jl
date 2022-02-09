function null()
end

halfway = Fae.@fo function halfway(x, y; loc=(0,0))
    x = 0.5*(loc[1] + x)
    y = 0.5*(loc[2] + y)
end

sinusoidal = Fae.@fo function sinusoidal(x, y, t)
    x = sin(p[tid, 2])
    y = sin(p[tid, 1])
end

polar_play = Fae.@fo function polar_play(x, y, t, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x) + theta*t

    y = 1-r
    x = theta/pi
end

polar = Fae.@fo function polar(x, y, t, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x) + theta

    y = r-1
    x = theta/pi
end

horseshoe = Fae.@fo function horseshoe(x, y, t)
    r = sqrt(x*x + y*y)
    if r < 0.001
        r = 0.001
    end

    x = (x-y)*(x+y)/r
    y = 2*x*y/r
end

heart = Fae.@fo function heart(x, y, t, theta)
    r = sqrt(x*x + y*y)
    theta = atan(y, x) + theta

    y = -r*cos(theta*r)
    x = r*sin(theta*r)
end

rotate = Fae.@fo function rotate(x, y, t, theta)
    x = x*cos(theta) - y*sin(theta)
    y = x*sin(theta) + y*cos(theta)
end

swirl = Fae.@fo function swirl(x, y, t)
    r = sqrt(y*y + x*x)

    v1 = x*cos(r*r) + y*sin(r*r)
    v2 = x*sin(r*r) - y*cos(r*r)

    y = v1
    x = v2
end

#=
function sierpinski(point::T, shape_vertex::T) where T
    return 0.5*(point .+ shape_vertex)
end
=#
