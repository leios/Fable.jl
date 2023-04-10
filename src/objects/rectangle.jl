export define_rectangle, update_rectangle!, define_square, update_square!
# Returns back H, colors, and probs for a square

rectangle_fum = @fum function rectangle_fum(y,x;
                                            vertex = 1,
                                            rotation = 0,
                                            position = (0,0),
                                            scale_x = 1,
                                            scale_y = 1)

    scale_x *= 0.5
    scale_y *= 0.5

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

    return point(0.5*(p_y + y), 0.5*(p_x + x))
end

function define_rectangle(; position::Union{Vector, Tuple, FractalInput}=(0,0),
                            rotation::Union{Number, FractalInput} = 0.0,
                            scale_x::Union{Number, FractalInput} = 1.0,
                            scale_y::Union{Number, FractalInput} = 1.0,
                            color = Shaders.grey)

    fums = define_rectangle_operators(position, rotation, scale_x, scale_y)
    color_set = define_color_operators(color; fnum = 4)

    fos = Tuple(FractalOperator(fums[i], color_set[i], 0.25) for i = 1:4)
    return Hutchinson((fos,))
end

# Returns back H, colors, and probs for a square
function define_square(; position::Union{Vector, Tuple, FractalInput}=(0,0),
                         rotation::Union{Number, FractalInput} = 0.0,
                         scale::Union{Number, FractalInput} = 1.0,
                         color = Shaders.grey)

    return define_rectangle(; position = position, rotation = rotation,
                              scale_x = scale, scale_y = scale, color = color)
end

# This specifically returns the fums for a square
function define_rectangle_operators(position::Union{Vector,Tuple,FractalInput},
                                    rotation::Union{Number, FractalInput},
                                    scale_x::Union{Number, FractalInput},
                                    scale_y::Union{Number, FractalInput})

    square_1 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 1)
    square_2 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 2)
    square_3 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 3)
    square_4 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 4)

    return (square_1, square_2, square_3, square_4)
end
