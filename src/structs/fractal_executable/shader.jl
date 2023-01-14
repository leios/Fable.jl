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
    return Shader(configure_fum(fum, fis; fum_type = :shader, name = name), fum,
                  fis, name, configure_fis!(fis))
end

function Shader(fum::FractalUserMethod; name = "shader")
    return Shader(configure_fum(fum; fum_type = :shader, name = name), fum,
                  Vector{FractalInput}(), name, Tuple(1))
end

function Shader(a::Shader, b::Shader; mix_function = overlay)
    if mix_function != overlay && mix_function != mix
        @warn("Shader mix type "*string(mix_function)*" not found!\n"*
              "Defaulting to standard mixing...")
        mix_function = mix
    end

    new_fis = vcat(a.fi_set, b.fi_set)
    new_name = a.name*"_"*b.name
    new_symbols = [a.symbols[i] for i = 1:length(a.symbols)]
    new_symbols = vcat(symbols, [b.symbols[i] for i = 1:length(b.symbols)])

    new_fum = mix_function(a.fum, b.fum)

    return Shader(configure_fum(new_fum; fum_type = :shader, name = new_name),
                  new_fum, new_fis, new_name, Tuple(new_symbols))
    
end

function Shader(shaders::Vector{Shader}; mix_function = mix)
    if mix_function != overlay && mix_function != mix
        @warn("Shader mix type "*string(mix_function)*" not found!\n"*
              "Defaulting to standard mixing...")
        mix_function = mix
    end

    new_fis = shaders[1].fi_set
    new_name = shaders[1].name
    new_symbols = [shaders[1].symbols[i] for i = 1:length(shaders[1].symbols)]
    all_fums = shaders[1].fum

    for i = 2:length(shaders)
        new_fis = vcat(new_fis, shaders[i].fi_set)
        new_name = new_name*"_"*shaders[i].name
        new_symbols = vcat(new_symbols,
            [shaders[i].symbols[i] for i = 1:length(shaders[i].symbols)])
        all_fums = vcat(all_fums, shaders[i].fum)
    end

    new_fum = mix_function(all_fums; fum_type = :shader)
    return Shader(configure_fum(new_fum; fum_type = :shader, name = new_name),
                  new_fum, new_fis, new_name, Tuple(new_symbols))
end

function update_fis!(S::Shader, fis::Vector{FractalInput})
    S.symbols = configure_fis!(fis)
end
