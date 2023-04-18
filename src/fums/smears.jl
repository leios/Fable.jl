export Smears

module Smears

import Fable.@fum
import Fable.point

stretch_and_rotate = @fum function stretch_and_rotate(
    y,x;
    object_position = (0,0),
    scale = (1,1),
    theta = 0)

    y = (y - object_position[1])*scale[1]
    x = (x - object_position[2])*scale[2]

    temp_x = x*cos(theta) - y*sin(theta)
    temp_y = x*sin(theta) + y*cos(theta)

    x = temp_x + object_position[2]
    y = temp_y + object_position[1]

    return point(y,x)
end

simple_smear = @fum function simple_smear(y,x;
                                          object_position = (0,0),
                                          previous_position = (0.0),
                                          previous_velocity = (0.0),
                                          factor = 10)
    temp = abs.(object_position .- previous_position)
    temp = ((temp .- previous_velocity) ./ factor) .+ 1

    x = (x-object_position[2])*temp[2] + object_position[2]
    y = (y-object_position[1])*temp[1] + object_position[1]
    return point(y,x)
end

end
