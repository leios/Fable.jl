# Returns back H, colors, and probs for a square
function define_rectangle(pos::Vector{FT}, theta::FT, scale_x::FT, scale_y,
                          color::Array{FT}; AT = Array,
                          name = "rectangle",
                          diagnostic = false) where FT <: AbstractFloat

    fos, fis = define_rectangle_operators(pos, theta, scale_x, scale_y)
    prob_set = (0.25, 0.25, 0.25, 0.25)
    color_set = [color for i = 1:4]
    return Hutchinson(fos, fis, color_set, prob_set; AT = AT, FT = FT,
                      name = name, diagnostic = diagnostic)
end

# Returns back H, colors, and probs for a square
function define_square(pos::Vector{FT}, theta::FT, scale::FT,
                       color::Array{FT}; AT = Array,
                       name = "square",
                       diagnostic = false) where FT <: AbstractFloat

    return define_rectangle(pos, theta, scale, scale, color; AT = AT,
                            name = name, diagnostic = diagnostic)
end

# This specifically returns the fos for a square
function define_rectangle_operators(pos::Vector{FT}, theta::FT,
                                    scale_x, scale_y) where FT <: AbstractFloat


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

    square_1 = halfway(loc = p1)
    square_2 = halfway(loc = p2)
    square_3 = halfway(loc = p3)
    square_4 = halfway(loc = p4)

    return [square_1, square_2, square_3, square_4], [p1, p2, p3, p4]
end

function update_rectangle!(H, pos, theta, scale_x, scale_y; fnum = 4)
    update_rectangle!(H, pos, theta, scale_x, scale_y, nothing; fnum = fnum)
end

function update_square!(H, pos, theta, scale; fnum = 4)
    update_rectangle!(H, pos, theta, scale, scale, nothing; fnum = fnum)
end

function update_square!(H::Hutchinson, pos::Vector{F}, theta::F,
                        scale, color::Union{Array{F}, Nothing};
                        FT = Float64, AT = Array,
                        fnum = 4) where F <: AbstractFloat
    update_rectangle!(H, pos, theta, scale, scale, color; FT = FT, AT = AT,
                      fnum = fnum)
end

function update_rectangle!(H::Hutchinson, pos::Vector{F}, theta::F,
                           scale_x, scale_y, color::Union{Array{F}, Nothing};
                           FT = Float64, AT = Array,
                           fnum = 4) where F <: AbstractFloat

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
        H.color_set = new_color_array([color for i = 1:5], fnum;
                                      FT = FT, AT = AT)
    end

end
