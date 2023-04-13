export Flames

module Flames
import Fable.@fum

identity = @fum function identity(y, x)
    return point(y, x)
end

scale = @fum function scale(y, x; scale = (1,1))
    x = scale[2]*x
    y = scale[1]*y
    return point(y,x)
end

scale_and_translate = @fum function scale_and_translate(y, x;
                                                       translation = (0,0),
                                                       scale = (1, 1))
    x = scale[2]*x + translation[2]
    y = scale[1]*y + translation[1]
    return point(y,x)
end


perspective = @fum function perspective(y, x; theta = 0.5*pi, dist = 1)
    C = dist/(dist - y*sin(theta))
    x *= C
    y *= C*cos(theta)
    return point(y,x)
end

cloud = @fum function cloud(x, y)
    x *= 2
    y = -(y+exp(-abs(y+2)^2/2))
    return point(y,x)
end

waves = @fum function waves(y, x; c = 1, f = 1, b = 1, e = 1)
    x_temp = x

    x += b * sin(y/c^2)
    y += e * sin(x_temp/f^2)
    return point(y,x)
end

fae_cross = @fum function fae_cross(y, x)
    val = sqrt(1/(x^2 + y^2)^2)
    x *= val
    y *= val
    return point(y,x)
end

fan = @fum function fan(y, x; c = 1, f = 1)
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

    return point(y,x)
end

popcorn = @fum function popcorn(y, x; c = 1, f = 1)
    x_temp = x
    x += c*sin(tan(3*y))
    y += f*sin(tan(3*x_temp))
    return point(y,x)
end

shift = @fum function shift(y, x; loc = (0,0))
    x += loc[2]
    y += loc[1]
    return point(y,x)
end

antibubble = @fum function antibubble(y, x)
    r2 = (x*x + y*y)
    c = r2/4
    x = c*x
    y = c*y
    return point(y,x)
end

bubble = @fum function bubble(y, x)
    r2 = (x*x + y*y)
    c = 4/(4+r2)
    x = c*x
    y = c*y
    return point(y,x)
end

halfway = @fum function halfway(y, x; loc=(0,0))
    x = 0.5*(loc[2] + x)
    y = 0.5*(loc[1] + y)
    return point(y,x)
end

sinusoidal = @fum function sinusoidal(y, x)
    x = sin(x)
    y = sin(y)
    return point(y,x)
end

polar = @fum function polar(y, x)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x)

    y = r-1
    x = theta/pi
    return point(y,x)
end

horseshoe = @fum function horseshoe(y, x)
    r = sqrt(x*x + y*y)
    if r < 0.001
        r = 0.001
    end

    v1 = (x-y)*(x+y)/r
    v2 = 2*x*y/r

    x = v1
    y = v2
    return point(y,x)
end

heart = @fum function heart(y, x)
    r = sqrt(x*x + y*y)
    theta = atan(y, x)

    y = -r*cos(theta*r)
    x = r*sin(theta*r)
    return point(y,x)
end

rotate = @fum function rotate(y, x; theta = 0.5*pi)
    x = x*cos(theta) - y*sin(theta)
    y = x*sin(theta) + y*cos(theta)
    return point(y,x)
end

swirl = @fum function swirl(y, x)
    r = sqrt(y*y + x*x)

    v1 = x*cos(r*r) + y*sin(r*r)
    v2 = x*sin(r*r) - y*cos(r*r)

    y = v1
    x = v2
    return point(y,x)
end
end
