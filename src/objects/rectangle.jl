export define_rectangle, update_rectangle!
# Returns back H, colors, and probs for a square
function define_rectangle(pos::Vector{FT}, theta::FT, scale_x::FT, scale_y,
                          color; name = "rectangle",
                          diagnostic = false) where FT <: AbstractFloat

    fums, fis = define_rectangle_operators(pos, theta, scale_x, scale_y;
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
function define_square(pos::Vector{FT}, theta::FT, scale::FT,
                       color; name = "square",
                       diagnostic = false) where FT <: AbstractFloat

    return define_rectangle(pos, theta, scale, scale, color;
                            name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a square
function define_rectangle_operators(pos::Vector{FT}, theta::FT,
                                    scale_x, scale_y;
                                    name="rectangle") where FT <: AbstractFloat


    scale_x *= 0.5
    scale_y *= 0.5

    p1_x = scale_x*cos(theta) - scale_y*sin(theta) + pos[2]
    p1_y = scale_x*sin(theta) + scale_y*cos(theta) + pos[1]
    p1 = fi("p1_"*name, (p1_x, p1_y))

    p2_x = scale_x*cos(theta) + scale_y*sin(theta) + pos[2]
    p2_y = scale_x*sin(theta) - scale_y*cos(theta) + pos[1]
    p2 = fi("p2_"*name, (p2_x, p2_y))

    p3_x = - scale_x*cos(theta) + scale_y*sin(theta) + pos[2]
    p3_y = - scale_x*sin(theta) - scale_y*cos(theta) + pos[1]
    p3 = fi("p3_"*name, (p3_x, p3_y))

    p4_x = - scale_x*cos(theta) - scale_y*sin(theta) + pos[2]
    p4_y = - scale_x*sin(theta) + scale_y*cos(theta) + pos[1]
    p4 = fi("p4_"*name, (p4_x, p4_y))

    square_1 = Flames.halfway(loc = p1)
    square_2 = Flames.halfway(loc = p2)
    square_3 = Flames.halfway(loc = p3)
    square_4 = Flames.halfway(loc = p4)

    return [square_1, square_2, square_3, square_4], [p1, p2, p3, p4]
end

function update_rectangle!(H, pos, theta, scale_x, scale_y; fnum = 4)
    update_rectangle!(H, pos, theta, scale_x, scale_y, nothing; fnum = fnum)
end

function update_square!(H, pos, theta, scale; fnum = 4)
    update_rectangle!(H, pos, theta, scale, scale, nothing; fnum = fnum)
end

function update_square!(H::Hutchinson, pos::Vector{FT}, theta::FT,
                        scale, color::Union{Array{FT}, Nothing};
                        fnum = 4) where FT <: AbstractFloat
    update_rectangle!(H, pos, theta, scale, scale, color; fnum = fnum)
end

function update_rectangle!(H::Hutchinson, pos::Vector{FT}, theta::FT,
                           scale_x, scale_y, color::Union{Array{FT}, Nothing};
                           fnum = 4) where FT <: AbstractFloat

    p1_x = scale_x*cos(theta) - scale_y*sin(theta) + pos[1]
    p1_y = scale_x*sin(theta) + scale_y*cos(theta) + pos[2]
    p1 = fi("p1", (p1_x, p1_y))

    p2_x = scale_x*cos(theta) + scale_y*sin(theta) + pos[1]
    p2_y = scale_x*sin(theta) - scale_y*cos(theta) + pos[2]
    p2 = fi("p2", (p2_x, p2_y))

    p3_x = - scale_x*cos(theta) + scale_y*sin(theta) + pos[1]
    p3_y = - scale_x*sin(theta) - scale_y*cos(theta) + pos[2]
    p3 = fi("p3", (p3_x, p3_y))

    p4_x = - scale_x*cos(theta) - scale_y*sin(theta) + pos[1]
    p4_y = - scale_x*sin(theta) + scale_y*cos(theta) + pos[2]
    p4 = fi("p4", (p4_x, p4_y))

    H.symbols = configure_fis!([p1, p2, p3, p4])
    if color != nothing
        H.color_set = new_color_array([color for i = 1:4], fnum)
    end

end
