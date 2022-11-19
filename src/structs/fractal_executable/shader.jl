# fee = Fractal Executable
export fee, Shader

mutable struct Shader <: FractalExecutable
    op
    fum::FractalUserMethod
    fi_set::Vector{FractalInput}
    name::String
    symbols::Union{NTuple, Tuple}
end

fee(S::Type{Shader}, args...; kwargs...) = Shader(args...; kwargs...)

function Shader(; name = "shader")
    return Shader(configure_fum(color_null; fum_type = :shader, name = name),
                  color_null, Vector{FractalInput}(), name, Tuple(1))
end

function Shader(fum::FractalUserMethod, fis::Vector{FractalInput};
                name = "shader")
    return Shader(configure_fum(fum; fum_type = :shader, name = name), fum,
                  fis, name, configure_fis!(fis))
end

function Shader(fum::FractalUserMethod; name = "shader")
    return Shader(configure_fum(fum; fum_type = :shader, name = name), fum,
                  Vector{FractalInput}(), name, Tuple(1))
end

function update_fis!(S::Shader, fis::Vector{FractalInput})
    S.symbols = configure_fis!(fis)
end
