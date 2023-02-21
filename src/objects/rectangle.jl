export define_rectangle, update_rectangle!, define_square, update_square!
# Returns back H, colors, and probs for a square

rectangle_fum = @fum function rectangle_fum(x, y;
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
        error("vertex "*string(vertex)*" not available for rectangles!")
    end

    x = 0.5*(p_x + x)
    y = 0.5*(p_y + y)
end
function define_rectangle(; position::Union{Vector, Tuple, FractalInput}=(0,0),
                            rotation::Union{Number, FractalInput} = 0.0,
                            scale_x::Union{Number, FractalInput} = 1.0,
                            scale_y::Union{Number, FractalInput} = 1.0,
                            color = Shaders.grey,
                            name = "rectangle",
                            diagnostic = false)

    fums, fis = define_rectangle_operators(position, rotation, scale_x, scale_y;
                                           name = name)
    if length(color) == 1 || eltype(color) <: Number
        color_set = [create_color(color) for i = 1:4]
    elseif length(color) == 4
        color_set = [create_color(color[i]) for i = 1:4]
    else
        error("cannot convert colors for rectangle, "*
              "maybe improper number of functions?")
    end
    fos = [FractalOperator(fums[i], color_set[i], 0.25) for i = 1:4]
    return Hutchinson(fos, fis; name = name, diagnostic = diagnostic)
end

# Returns back H, colors, and probs for a square
function define_square(; position::Union{Vector, Tuple, FractalInput}=(0,0),
                         rotation::Union{Number, FractalInput} = 0.0,
                         scale::Union{Number, FractalInput} = 1.0,
                         color = Shaders.grey,
                         name = "square",
                         diagnostic = false)

    return define_rectangle(; position = position, rotation = rotation,
                              scale_x = scale, scale_y = scale, color = color,
                              name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a square
function define_rectangle_operators(position::Union{Vector,Tuple,FractalInput},
                                    rotation::Union{Number, FractalInput},
                                    scale_x::Union{Number, FractalInput},
                                    scale_y::Union{Number, FractalInput};
                                    name="rectangle")

    if !isa(position, FractalInput)
        position = fi("position", Tuple(position))
    end

    if !isa(rotation, FractalInput)
        rotation = fi("rotation", rotation)
    end

    if !isa(scale_x, FractalInput)
        scale_x = fi("scale_x", scale_x)
    end

    if !isa(scale_y, FractalInput)
        scale_y = fi("scale_y", scale_y)
    end

    square_1 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 1)
    square_2 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 2)
    square_3 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 3)
    square_4 = rectangle_fum(position = position, rotation = rotation,
                             scale_x = scale_x, scale_y = scale_y, vertex = 4)

    return [square_1, square_2, square_3, square_4],
           [position, rotation, scale_x, scale_y]
end

function update_rectangle!(H, position, rotation, scale_x, scale_y; fnum = 4)
    update_rectangle!(H, position, rotation, scale_x, scale_y, nothing; fnum = fnum)
end

function update_square!(H, position, rotation, scale; fnum = 4)
    update_rectangle!(H, position, rotation, scale, scale, nothing; fnum = fnum)
end

function update_square!(H::Hutchinson, position::Union{Vector, Tuple}, rotation,
                        scale, color::Union{Array, Tuple, Nothing}; fnum = 4)
    update_rectangle!(H, position, rotation, scale, scale, color; fnum = fnum)
end

function update_rectangle!(H::Hutchinson;
                           position::Union{Vector, Tuple,
                                           FractalInput, Nothing}=nothing,
                           rotation::Union{Number, FractalInput,
                                           Nothing}=nothing,
                           scale_x::Union{Number, FractalInput,
                                           Nothing}=nothing,
                           scale_y::Union{Number, FractalInput,
                                           Nothing}=nothing,
                           color::Union{Array, Tuple, Nothing}, fnum = 4)

    if position != nothing
        if isa(position, FractalInput)
            H.fi_set[1] = position
        else
            H.fi_set[1] = FractalInput(H.fi_set[3].index,
                                       H.fi_set[3].name,
                                       Tuple(position))
        end
    end

    if rotation != nothing
        if isa(rotation, FractalInput)
            H.fi_set[2] = rotation
        else
            H.fi_set[2] = FractalInput(H.fi_set[4].index,
                                       H.fi_set[4].name,
                                       value(rotation))
        end
    end

    if scale_x != nothing
        if isa(scale_x, FractalInput)
            H.fi_set[2] = scale_x
        else
            H.fi_set[2] = FractalInput(H.fi_set[4].index,
                                       H.fi_set[4].name,
                                       value(scale_x))
        end
    end

    if scale_y != nothing
        if isa(scale_y, FractalInput)
            H.fi_set[2] = scale_y
        else
            H.fi_set[2] = FractalInput(H.fi_set[4].index,
                                       H.fi_set[4].name,
                                       value(scale_y))
        end
    end

    H.symbols = configure_fis!(H.fi_set)
    if color != nothing
        H.color_set = new_color_array([color for i = 1:4], fnum)
    end

end
