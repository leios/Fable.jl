# Returns back H, colors, and probs for a square
function define_square(pos::Vector{FT}, rotation::FT, scale::FT,
                       color::Array{FT}; AT = Array) where FT <: AbstractFloat

    fos, fis = define_square_operators(pos, rotation)
    prob_set = (0.25, 0.25, 0.25, 0.25)
    color_set = [color for i = 1:4]
    println(color_set)
    return Hutchinson(fos, fis, color_set, prob_set; AT = AT, FT = FT)
end

# This specifically returns the fos for a square
function define_square_operators(pos::Vector{FT}, rotation::FT;
                                 scale = 1.0) where FT <: AbstractFloat

    p1 = (0,1)
    p2 = (1,0)
    p3 = (0,-1)
    p4 = (-1,0)
    #p1 = @fi p1 = [0,1]
    #p2 = @fi p2 = [1,0]
    #p3 = @fi p3 = [0,-1]
    #p4 = @fi p4 = [-1,0]
    square_1 = halfway(loc = p1)
    square_2 = halfway(loc = p2)
    square_3 = halfway(loc = p3)
    square_4 = halfway(loc = p4)

    #return [square_1, square_2, square_3, square_4], [p1, p2, p3, p4]
    return [square_1, square_2, square_3, square_4], []
end
