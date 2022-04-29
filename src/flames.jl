identity = @fo function identity(x, y)
end

waves = @fo function waves(x, y; c = 1, f = 1, b = 1, e = 1)
    x_temp = x

    x += b * sin(y/c^2)
    y += e * sin(x_temp/f^2)
end

fae_cross = @fo function fae_cross(x, y)
    val = sqrt(1/(x^2 + y^2)^2)
    x *= val
    y *= val
end

fan = @fo function fan(x, y; c = 1, f = 1)
    t = pi*c^2
    theta = atan(y,x)

    r = sqrt(x^2+y^2)

    if (theta + f) % t > 0.5*t
        x = r*cos(theta - 0.5*t)
        y = r*sin(theta - 0.5*t)
    elseif (theta + f) % t <= 0.5*t
        x = r*cos(theta + 0.5*t)
        y = r*sin(theta + 0.5*t)
    end

end

popcorn = @fo function popcorn(x, y; c = 1, f = 1)
    x_temp = x
    x += c*sin(tan(3*y))
    y += f*sin(tan(3*x_temp))
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
    theta = atan(y, x)
    theta += theta*t

    y = 1-r
    x = theta/pi
end

polar = @fo function polar(x, y)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x)


    y = r-1
    x = theta/pi
end

horseshoe = @fo function horseshoe(x, y)
    r = sqrt(x*x + y*y)
    if r < 0.001
        r = 0.001
    end

    v1 = (x-y)*(x+y)/r
    v2 = 2*x*y/r

    x = v1
    y = v2
end

heart = @fo function heart(x, y)
    r = sqrt(x*x + y*y)
    theta = atan(y, x)

    y = -r*cos(theta*r)
    x = r*sin(theta*r)
end

rotate = @fo function rotate(x, y; theta = 0.5*pi)
    x = x*cos(theta) - y*sin(theta)
    y = x*sin(theta) + y*cos(theta)
end

swirl = @fo function swirl(x, y)
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
