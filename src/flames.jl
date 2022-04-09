identity = @fo function identity(x, y)
end

shift = @fo function shift(x, y; loc = (0,0))
    x += loc[2]
    y += loc[1]
end

antibubble = @fo function antibubble(x, y)
    r2 = (x*x + y*y)
    c = r2/4
    x = c*x
    y = c*y
end

bubble = @fo function bubble(x, y)
    r2 = (x*x + y*y)
    c = 4/(4+r2)
    x = c*x
    y = c*y
end

halfway = @fo function halfway(x, y; loc=(0,0))
    x = 0.5*(loc[1] + x)
    y = 0.5*(loc[2] + y)
end

sinusoidal = @fo function sinusoidal(x, y)
    x = sin(x)
    y = sin(y)
end

polar_play = @fo function polar_play(x, y, t, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x) + theta*t

    y = 1-r
    x = theta/pi
end

polar = @fo function polar(x, y, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x) + theta

    y = r-1
    x = theta/pi
end

horseshoe = @fo function horseshoe(x, y, t)
    r = sqrt(x*x + y*y)
    if r < 0.001
        r = 0.001
    end

    x = (x-y)*(x+y)/r
    y = 2*x*y/r
end

heart = @fo function heart(x, y, t)
    r = sqrt(x*x + y*y)
    theta = atan(y, x)

    y = -r*cos(r)
    x = r*sin(r)
end

rotate = @fo function rotate(x, y, t, theta)
    x = x*cos(theta) - y*sin(theta)
    y = x*sin(theta) + y*cos(theta)
end

swirl = @fo function swirl(x, y, t)
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
