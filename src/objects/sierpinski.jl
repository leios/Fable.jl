function define_sierpinski(A::Vector{FT}, B::Vector{FT}, C::Vector{FT},
                           color::Array{FT}; AT = Array,
                           name = "sierpinski",
                           diagnostic = false) where FT <: AbstractFloat
    define_sierpinski(A, B, C, color, color, color;
                      AT = AT, name = name, diagnostic = diagnostic)
end

function define_sierpinski(A::Vector{FT}, B::Vector{FT}, C::Vector{FT},
                           color_A::Array{FT}, color_B::Array{FT},
                           color_C::Array{FT}; AT = Array,
                           name = "sierpinski", 
                           diagnostic = false) where FT <: AbstractFloat

    fos, fis = define_sierpinski_operators(A, B, C)
    prob_set = (0.33, 0.33, 0.34)
    color_set = [color_A, color_B, color_C]
    return Hutchinson(fos, fis, color_set, prob_set; AT = AT, FT = FT,
                      name = name, diagnostic = diagnostic)
end

# This specifically returns the fos for a square
function define_sierpinski_operators(A::Vector{FT}, B::Vector{FT},
                                     C::Vector{FT}) where FT <: AbstractFloat

    f_A = fi("A",A)
    f_B = fi("B",B)
    f_C = fi("C",C)

    s_1 = halfway(loc = f_A)
    s_2 = halfway(loc = f_B)
    s_3 = halfway(loc = f_C)

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
