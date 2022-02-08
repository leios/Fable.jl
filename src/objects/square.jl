# Returns back H, colors, and probs for a square
function define_square(pos::Vector{FT}, theta::FT, scale::FT,
                       color::Array{FT}; AT = Array) where FT <: AbstractFloat

    fos, fis = define_square_operators(pos, theta, scale)
    prob_set = (0.25, 0.25, 0.25, 0.25)
    color_set = [color for i = 1:4]
    println(color_set)
    return Hutchinson(fos, fis, color_set, prob_set; AT = AT, FT = FT)
end

# This specifically returns the fos for a square
function define_square_operators(pos::Vector{FT}, theta::FT,
                                 scale) where FT <: AbstractFloat


    p1_x = scale*cos(theta) - scale*sin(theta) + pos[1]
    p1_y = scale*sin(theta) + scale*cos(theta) + pos[2]
    p1 = fi("p1", (p1_x, p1_y))

    p2_x = scale*cos(theta) + scale*sin(theta) + pos[1]
    p2_y = scale*sin(theta) - scale*cos(theta) + pos[2]
    p2 = fi("p2", (p2_x, p2_y))

    p3_x = - scale*cos(theta) + scale*sin(theta) + pos[1]
    p3_y = - scale*sin(theta) - scale*cos(theta) + pos[2]
    p3 = fi("p3", (p3_x, p3_y))

    p4_x = - scale*cos(theta) - scale*sin(theta) + pos[1]
    p4_y = - scale*sin(theta) + scale*cos(theta) + pos[2]
    p4 = fi("p4", (p4_x, p4_y))

    square_1 = halfway(loc = p1)
    square_2 = halfway(loc = p2)
    square_3 = halfway(loc = p3)
    square_4 = halfway(loc = p4)

    return [square_1, square_2, square_3, square_4], [p1, p2, p3, p4]
end

function update_square!(H, pos, theta, scale)
    update_square!(H, pos, theta, scale, nothing)
end

function update_square!(H::Hutchinson, pos::Vector{F}, theta::F,
                       scale, color::Union{Array{F}, Nothing};
                       FT = Float64, AT = Array) where F <: AbstractFloat

    p1_x = scale*cos(theta) - scale*sin(theta) + pos[1]
    p1_y = scale*sin(theta) + scale*cos(theta) + pos[2]
    p1 = fi("p1", (p1_x, p1_y))

    p2_x = scale*cos(theta) + scale*sin(theta) + pos[1]
    p2_y = scale*sin(theta) - scale*cos(theta) + pos[2]
    p2 = fi("p2", (p2_x, p2_y))

    p3_x = - scale*cos(theta) + scale*sin(theta) + pos[1]
    p3_y = - scale*sin(theta) - scale*cos(theta) + pos[2]
    p3 = fi("p3", (p3_x, p3_y))

    p4_x = - scale*cos(theta) - scale*sin(theta) + pos[1]
    p4_y = - scale*sin(theta) + scale*cos(theta) + pos[2]
    p4 = fi("p4", (p4_x, p4_y))

    H.symbols = configure_fis!([p1, p2, p3, p4])
    if color != nothing
        H.color_set = new_color_array([color for i = 1:4], 4; FT = FT, AT = AT)
    end

end
