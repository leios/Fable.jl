export in_ellipse, in_rectangle

@inline function in_ellipse(y, x, position, rotation, r1, r2)
    r = sqrt(x*x + y*y)
    theta = atan(y,x)
    x2 = r*cos(theta-rotation)
    y2 = r*sin(theta-rotation)
    if (x2-position[2])^2/r2^2 + (y2-position[1])^2/r1^2 <= 1
        return true
    end

    return false
end

@inline function in_rectangle(y, x, position, rotation, scale_x, scale_y)
    r = sqrt(x*x + y*y)
    theta = atan(y,x)
    x2 = r*cos(theta-rotation)
    y2 = r*sin(theta-rotation)
    if abs(x2-position[2]) <= scale_x*0.5 &&
       abs(y2-position[1]) <= scale_y*0.5
        return true
    end

    return false
end
