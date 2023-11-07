export in_ellipse, in_rectangle, in_blob

@inline function in_ellipse(y, x, position, rotation, r1, r2)
    @inbounds x -= position[2]
    @inbounds y -= position[1]
    r = sqrt(x*x + y*y)
    theta = atan(y,x)
    x2 = r*cos(theta-rotation)
    y2 = r*sin(theta-rotation)
    if (x2)^2/r2^2 + (y2)^2/r1^2 <= 1
        return true
    end

    return false
end

@inline function in_rectangle(y, x, position, rotation, scale_x, scale_y)
    @inbounds x -= position[2]
    @inbounds y -= position[1]
    r = sqrt(x*x + y*y)
    theta = atan(y,x)
    x2 = r*cos(theta-rotation)
    y2 = r*sin(theta-rotation)
    if abs(x2) <= scale_x*0.5 && abs(y2) <= scale_y*0.5
        return true
    end

    return false
end

@inline function in_blob(y, x, position, rotation, radius,
                         frequencies, amplitudes)
    @inbounds x -= position[2]
    @inbounds y -= position[1]
    theta = atan(y, x)
    theta -= rotation

    y_val = radius*sin(theta)
    x_val = radius*cos(theta)
    for i = 1:length(frequencies)
        @inbounds y_val += amplitudes[i]*sin(frequencies[i]*theta)
        @inbounds x_val += amplitudes[i]*cos(frequencies[i]*theta)
    end

    if x*x + y*y <= x_val*x_val + y_val*y_val
        return true
    end

    return false
end
