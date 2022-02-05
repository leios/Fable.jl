function null()
end

halfway = Fae.@frop function halfway(x, y, p)
    x = 0.5*(p[1] + x)
    y = 0.5*(p[1] + y)
end

square_1 = Fae.@frop function square_1(x, y, t)
    scale = 0.5
    theta = 2*pi*t
    v1 = scale*cos(theta) - scale*sin(theta)
    v2 = scale*sin(theta) + scale*cos(theta)
    x = 0.5*(x+v1)
    y = 0.5*(y+v2)
end

square_2 = Fae.@frop function square_2(x, y, t)
    scale = 0.5
    theta = 2*pi*t
    v1 = scale*cos(theta) + scale*sin(theta)
    v2 = scale*sin(theta) - scale*cos(theta)
    x = 0.5*(x+v1)
    y = 0.5*(y+v2)
end

square_3 = Fae.@frop function square_3(x, y, t)
    scale = 0.5
    theta = 2*pi*t
    v1 = - scale*cos(theta) + scale*sin(theta)
    v2 = - scale*sin(theta) - scale*cos(theta)
    x = 0.5*(x+v1)
    y = 0.5*(y+v2)
end

square_4 = Fae.@frop function square_4(x, y, t)
    scale = 0.5
    theta = 2*pi*t
    v1 = - scale*cos(theta) - scale*sin(theta)
    v2 = - scale*sin(theta) + scale*cos(theta)
    x = 0.5*(x+v1)
    y = 0.5*(y+v2)
end

sinusoidal = Fae.@frop function sinusoidal(x, y, t)
    x = sin(p[tid, 2])
    y = sin(p[tid, 1])
end

polar_play = Fae.@frop function polar_play(x, y, t, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x) + theta*t

    y = 1-r
    x = theta/pi
end

polar = Fae.@frop function polar(x, y, t, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x) + theta

    y = r-1
    x = theta/pi
end

horseshoe = Fae.@frop function horseshoe(x, y, t)
    r = sqrt(x*x + y*y)
    if r < 0.001
        r = 0.001
    end

    x = (x-y)*(x+y)/r
    y = 2*x*y/r
end

heart = Fae.@frop function heart(x, y, t, theta)
    r = sqrt(x*x + y*y)
    theta = atan(y, x) + theta

    y = -r*cos(theta*r)
    x = r*sin(theta*r)
end

rotate = Fae.@frop function rotate(x, y, t, theta)
    x = x*cos(theta) - y*sin(theta)
    y = x*sin(theta) + y*cos(theta)
end

swirl = Fae.@frop function swirl(x, y, t)
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
