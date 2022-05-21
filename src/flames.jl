export Flames

module Flames
import Fae.@fum

identity = @fum function identity(x, y)
end

waves = @fum function waves(x, y; c = 1, f = 1, b = 1, e = 1)
    x_temp = x

    x += b * sin(y/c^2)
    y += e * sin(x_temp/f^2)
end

fae_cross = @fum function fae_cross(x, y)
    val = sqrt(1/(x^2 + y^2)^2)
    x *= val
    y *= val
end

fan = @fum function fan(x, y; c = 1, f = 1)
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

popcorn = @fum function popcorn(x, y; c = 1, f = 1)
    x_temp = x
    x += c*sin(tan(3*y))
    y += f*sin(tan(3*x_temp))
end

shift = @fum function shift(x, y; loc = (0,0))
    x += loc[2]
    y += loc[1]
end

antibubble = @fum function antibubble(x, y)
    r2 = (x*x + y*y)
    c = r2/4
    x = c*x
    y = c*y
end

bubble = @fum function bubble(x, y)
    r2 = (x*x + y*y)
    c = 4/(4+r2)
    x = c*x
    y = c*y
end

halfway = @fum function halfway(x, y; loc=(0,0))
    x = 0.5*(loc[1] + x)
    y = 0.5*(loc[2] + y)
end

sinusoidal = @fum function sinusoidal(x, y)
    x = sin(x)
    y = sin(y)
end

polar_play = @fum function polar_play(x, y, t, theta)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x)
    theta += theta*t

    y = 1-r
    x = theta/pi
end

polar = @fum function polar(x, y)
    r = sqrt(sum(x*x + y*y))
    theta = atan(y, x)


    y = r-1
    x = theta/pi
end

horseshoe = @fum function horseshoe(x, y)
    r = sqrt(x*x + y*y)
    if r < 0.001
        r = 0.001
    end

    v1 = (x-y)*(x+y)/r
    v2 = 2*x*y/r

    x = v1
    y = v2
end

heart = @fum function heart(x, y)
    r = sqrt(x*x + y*y)
    theta = atan(y, x)

    y = -r*cos(theta*r)
    x = r*sin(theta*r)
end

rotate = @fum function rotate(x, y; theta = 0.5*pi)
    x = x*cos(theta) - y*sin(theta)
    y = x*sin(theta) + y*cos(theta)
end

swirl = @fum function swirl(x, y)
    r = sqrt(y*y + x*x)

    v1 = x*cos(r*r) + y*sin(r*r)
    v2 = x*sin(r*r) - y*cos(r*r)

    y = v1
    x = v2
end
end
