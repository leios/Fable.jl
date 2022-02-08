# Returns back H, colors, and probs for a square
function define_square(pos::Vector{FT}, theta::FT, scale::FT,
                       color::Array{FT}; AT = Array) where FT <: AbstractFloat

    fos, fis = define_square_operators(pos, theta; scale = scale)
    prob_set = (0.25, 0.25, 0.25, 0.25)
    color_set = [color for i = 1:4]
    println(color_set)
    return Hutchinson(fos, fis, color_set, prob_set; AT = AT, FT = FT)
end

# This specifically returns the fos for a square
function define_square_operators(pos::Vector{FT}, theta::FT;
                                 scale = 1.0) where FT <: AbstractFloat


    p1_x = Fae.@fi p1_x = scale*cos(theta) - scale*sin(theta) + pos[1]
    p1_y = Fae.@fi p1_y = scale*sin(theta) + scale*cos(theta) + pos[2]
    #p1 = (v1, v2)
    p1 = Fae.@fi p1 = (p1_x, p1_y)

    p2_x = Fae.@fi p2_x = scale*cos(theta) + scale*sin(theta) + pos[1]
    p2_y = Fae.@fi p2_y = scale*sin(theta) - scale*cos(theta) + pos[2]
    #p2 = (v1, v2)
    p2 = Fae.@fi p2 = (p2_x, p2_y)

    p3_x = Fae.@fi p3_x = - scale*cos(theta) + scale*sin(theta) + pos[1]
    p3_y = Fae.@fi p3_y = - scale*sin(theta) - scale*cos(theta) + pos[2]
    #p3 = (v1, v2)
    p3 = Fae.@fi p3 = (p3_x, p3_y)

    p4_x = Fae.@fi p4_x = - scale*cos(theta) - scale*sin(theta) + pos[1]
    p4_y = Fae.@fi p4_y = - scale*sin(theta) + scale*cos(theta) + pos[2]
    #p4 = (v1, v2)
    p4 = Fae.@fi p4 = (p4_x, p4_y)

    #p1 = @fi p1 = [0,1]
    #p2 = @fi p2 = [1,0]
    #p3 = @fi p3 = [0,-1]
    #p4 = @fi p4 = [-1,0]
    square_1 = halfway(loc = p1)
    square_2 = halfway(loc = p2)
    square_3 = halfway(loc = p3)
    square_4 = halfway(loc = p4)

    return [square_1, square_2, square_3, square_4], [p1, p2, p3, p4]
    #return [square_1, square_2, square_3, square_4], []
end
