export create_rectangle, create_square
# Returns back H, colors, and probs for a square

rectangle_object = @fum function rectangle_object(y,x;
                                                  vertex = 1,
                                                  rotation = 0,
                                                  position = (0,0),
                                                  scale_x = 1,
                                                  scale_y = 1)

    scale_x *= 0.5
    scale_y *= 0.5

    @inbounds begin
        if vertex == 1
            p_x = scale_x*cos(rotation) - scale_y*sin(rotation) + position[2]
            p_y = scale_x*sin(rotation) + scale_y*cos(rotation) + position[1]
        elseif vertex == 2
            p_x = scale_x*cos(rotation) + scale_y*sin(rotation) + position[2]
            p_y = scale_x*sin(rotation) - scale_y*cos(rotation) + position[1]
        elseif vertex == 3
            p_x = - scale_x*cos(rotation) + scale_y*sin(rotation) + position[2]
            p_y = - scale_x*sin(rotation) - scale_y*cos(rotation) + position[1]
        elseif vertex == 4
            p_x = - scale_x*cos(rotation) - scale_y*sin(rotation) + position[2]
            p_y = - scale_x*sin(rotation) + scale_y*cos(rotation) + position[1]
        else
            p_x = 0.0
            p_y = 0.0
        end
    end

    return point(0.5*(p_y + y), 0.5*(p_x + x))
end

function create_rectangle(; position::Union{Vector, Tuple, FableInput}=(0,0),
                            rotation::Union{Number, FableInput} = 0.0,
                            scale_x::Union{Number, FableInput} = 1.0,
                            scale_y::Union{Number, FableInput} = 1.0,
                            color = Shaders.grey)

    fums = create_rectangle_operators(position, rotation, scale_x, scale_y)
    color_set = create_color_operators(color; fnum = 4)

    return fo(fums, color_set, (0.25 for i = 1:4))
end

# Returns back H, colors, and probs for a square
function create_square(; position::Union{Vector, Tuple, FableInput}=(0,0),
                         rotation::Union{Number, FableInput} = 0.0,
                         scale::Union{Number, FableInput} = 1.0,
                         color = Shaders.grey)

    return create_rectangle(; position = position, rotation = rotation,
                              scale_x = scale, scale_y = scale, color = color)
end

# This specifically returns the fums for a square
function create_rectangle_operators(position::Union{Vector,Tuple,FableInput},
                                    rotation::Union{Number, FableInput},
                                    scale_x::Union{Number, FableInput},
                                    scale_y::Union{Number, FableInput})

    square_1 = rectangle_object(position = position, rotation = rotation,
                                scale_x = scale_x, scale_y = scale_y,
                                vertex = 1)
    square_2 = rectangle_object(position = position, rotation = rotation,
                                scale_x = scale_x, scale_y = scale_y,
                                vertex = 2)
    square_3 = rectangle_object(position = position, rotation = rotation,
                                scale_x = scale_x, scale_y = scale_y,
                                vertex = 3)
    square_4 = rectangle_object(position = position, rotation = rotation,
                                scale_x = scale_x, scale_y = scale_y,
                                vertex = 4)

    return (square_1, square_2, square_3, square_4)
end
