module Smears

import Fae.@fum

simple_smear = @fum function simple_smear(x,y; factor = 10,
                                          object_position = (0,0),
                                          previous_position = (0.0),
                                          previous_velocity = (0.0))
    temp = abs(object_position .- previous_position)
    temp = (temp .- previous_velocity) / factor

    x = (x-object_position[2])*temp + object_position[2]
    y = (y-object_position[1])*temp + object_position[1]
end

end
