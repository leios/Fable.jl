function in_ellipse(position, rotation, r1, r2)

    if (x-position[2])^2/r2^2 + (y-position[1])^2/r1^2 <= 1
        return true
    end

    return false
end

function in_rectangle(x, y, position, rotation, scale_x, scale_y)

    if (abs(x-cos(rotation)-position[2]) <= scale_x*0.5 &&
       (abs(y-sin(rotation)-position[1]) <= scale_y*0.5
        return true
    end

    return false
end

