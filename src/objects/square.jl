# Returns back H, colors, and probs for a square
function define_square(pos::Vector{FT}, rotation::FT, scale::FT,
                       color::Array{FT}; AT = Array) where FT <: AbstractFloat

    frops = define_square_operators(pos, rotation)
    prob_set = (0.25, 0.25, 0.25, 0.25)
    color_set = [color for i = 1:4]
    println(color_set)
    return Hutchinson(frops, color_set, prob_set, 4; AT = AT, FT = FT)
end

# This specifically returns the frops for a square
function define_square_operators(pos::Vector{FT}, rotation::FT;
                                 scale = 1.0) where FT <: AbstractFloat

    scale = Fae.@frop scale = scale
    theta = Fae.@frop theta = rotation
    pos = Fae.@frop pos = pos
    square_1 = Fae.@frop function square_1(x, y, t, theta, scale, pos)
        v1 = scale*cos(theta) - scale*sin(theta) + pos[1]
        v2 = scale*sin(theta) + scale*cos(theta) + pos[2]
        x = 0.5*(x+v1)
        y = 0.5*(y+v2)
    end

    square_2 = Fae.@frop function square_2(x, y, t, theta, scale, pos)
        v1 = scale*cos(theta) + scale*sin(theta) + pos[1]
        v2 = scale*sin(theta) - scale*cos(theta) + pos[2]
        x = 0.5*(x+v1)
        y = 0.5*(y+v2)
    end

    square_3 = Fae.@frop function square_3(x, y, t, theta, scale, pos)
        v1 = - scale*cos(theta) + scale*sin(theta) + pos[1]
        v2 = - scale*sin(theta) - scale*cos(theta) + pos[2]
        x = 0.5*(x+v1)
        y = 0.5*(y+v2)
    end

    square_4 = Fae.@frop function square_4(x, y, t, theta, scale, pos)
        v1 = - scale*cos(theta) - scale*sin(theta) + pos[1]
        v2 = - scale*sin(theta) + scale*cos(theta) + pos[2]
        x = 0.5*(x+v1)
        y = 0.5*(y+v2)
    end

    return [square_1, square_2, square_3, square_4, scale, theta, pos]

end
