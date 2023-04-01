# fee = Fractal Executable
export fee, Shader

mutable struct Shader <: FractalExecutable
    fxs::Tuple{Function}
    kwargs::Tuple{NamedTuple}
    fis::Vector{FractalInput}
end

fee(S::Type{Shader}, args...; kwargs...) = Shader(args...; kwargs...)

function Shader(fum::Union{FractalUserMethod, Tuple}; name = "shader")
    return Shader(fum, name)
end

function Shader(a::Shader, b::Shader; mix_function = overlay)
    new_name = a.name*"_"*b.name

    return Shader((a.fums, b.fums), name = new_name)
    
end

function Shader(shaders::Vector{Shader}; mix_function = mix)
    all_fums = [shaders[i].fums for i = 1:length(shaders)]
    name = shaders[1].name

    for i = 2:length(shaders)
        new_name = new_name*"_"*shaders[i].name
    end

    return Shader(Tuple(all_fums), new_name)
end
