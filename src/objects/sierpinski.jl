export define_sierpinski, update_sierpinski!
function define_sierpinski(A::Vector{FT}, B::Vector{FT}, C::Vector{FT},
                           color; AT = Array,
                           name = "sierpinski",
                           diagnostic = false) where FT <: AbstractFloat
    fums, fis = define_sierpinski_operators(A, B, C)
    if length(color) == 1
        color_set = [color for i = 1:3]
    else
        color_set = [color[i] for i = 1:3]
    end
    fos = [FractalOperator(fums[i], color_set[i], 1/3) for i = 1:3]

    return Hutchinson(fos, fis; AT = AT, FT = FT,
                      name = name, diagnostic = diagnostic)
end

# This specifically returns the fums for a sierpinski triangle
function define_sierpinski_operators(A::Vector{FT}, B::Vector{FT},
                                     C::Vector{FT}) where FT <: AbstractFloat

    f_A = fi("A",A)
    f_B = fi("B",B)
    f_C = fi("C",C)

    s_1 = Flames.halfway(loc = f_A)
    s_2 = Flames.halfway(loc = f_B)
    s_3 = Flames.halfway(loc = f_C)

    return [s_1, s_2, s_3], [f_A,f_B,f_C]
end

function update_sierpinski!(H::Hutchinson, A::Vector{F}, B::Vector{F},
                            C::Vector{F};
                            FT = Float64, AT = Array) where F <: AbstractFloat

    update_sierpinski!(H, A, B, C, nothing, nothing, nothing)
end

function update_sierpinski!(H::Hutchinson, A::Vector{F}, B::Vector{F},
                            C::Vector{F}, color::Union{Array{F}, Nothing};
                            FT = Float64, AT = Array) where F <: AbstractFloat

    update_sierpinski!(H, A, B, C, color, color, color)
end

function update_sierpinski!(H::Hutchinson, A::Vector{F}, B::Vector{F},
                            C::Vector{F}, color_A::Union{Array{F}, Nothing},
                            color_B::Union{Array{F}, Nothing},
                            color_C::Union{Array{F}, Nothing};
                            FT = Float64, AT = Array) where F <: AbstractFloat

    f_A = fi("A",A)
    f_B = fi("B",B)
    f_C = fi("C",C)

    H.symbols = configure_fis!([f_A, f_B, f_C])
    if color_A != nothing
        H.color_set = new_color_array([color_A, color_B, color_C], 3;
                                      FT = FT, AT = AT)
    end

end
