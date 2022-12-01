export define_triangle, update_triangle!

triangle_fill = @fum function triangle_fill(x,y;
                                            A = (0,0),
                                            B = (0,0),
                                            C = (0,0))
    midpoint = (A .+ B .+ C) ./ 3

    x = midpoint[2] - (x - midpoint[2]) * 0.5
    y = midpoint[1] - (y - midpoint[1]) * 0.5
end

function define_triangle(; A = [FT(sqrt(3)/4), -0.5],
                           B = [FT(-sqrt(3)/4), 0],
                           C = [FT(sqrt(3)/4), 0.5],
                           color = Shaders.gray,
                           name = "triangle",
                           chosen_fx = :fill,
                           diagnostic = false) where FT <: AbstractFloat
    fums, fis = define_triangle_operators(A, B, C; name = name)

    fnum = 3
    if chosen_fx == :fill
        fnum = 4
    end

    if length(color) == 1 || eltype(color) <: Number
        color_set = [create_color(color) for i = 1:fnum]
    elseif length(color) == fnum
        color_set = [create_color(color[i]) for i = 1:fnum]
    else
        error("cannot convert colors for triangle, "*
              "maybe improper number of functions?")
    end
    fos = [FractalOperator(fums[i], color_set[i], 1/fnum) for i = 1:fnum]

    return Hutchinson(fos, fis; name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a triangle triangle
function define_triangle_operators(A::Vector{FT}, B::Vector{FT},
                                   C::Vector{FT}; chosen_fx = :fill,
                                   name="triangle") where FT <: AbstractFloat

    if chosen_fx != :sierpinski && chosen_fx != :fill
        error("Cannot create triangle with ", string(chosen_fx), " function!")
    end

    f_A = fi("A_"*name,A)
    f_B = fi("B_"*name,B)
    f_C = fi("C_"*name,C)

    s_1 = Flames.halfway(loc = f_A)
    s_2 = Flames.halfway(loc = f_B)
    s_3 = Flames.halfway(loc = f_C)
    if chosen_fx == :fill
        s_4 = triangle_fill(A = f_A, B = f_B, C = f_C)

        return [s_1, s_2, s_3, s_4], [f_A,f_B,f_C]
    elseif chosen_fx == :sierpinski
        return [s_1, s_2, s_3], [f_A,f_B,f_C]
    end
end

function update_triangle!(H::Hutchinson, A::Vector{FT}, B::Vector{FT},
                          C::Vector{FT}) where FT <: AbstractFloat

    update_triangle!(H, A, B, C, nothing)
end

function update_triangle!(H::Hutchinson, A::Vector{FT}, B::Vector{FT},
                          C::Vector{FT},
                          color::Union{Array{FT}, Nothing}) where FT <: AbstractFloat

    f_A = fi("A",A)
    f_B = fi("B",B)
    f_C = fi("C",C)

    H.symbols = configure_fis!([f_A, f_B, f_C])
    if color != nothing
        H.color_set = new_color_array(color)
    end

end
