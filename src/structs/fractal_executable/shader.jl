export Shader

mutable struct Shader <: FractalExecutable
    fxs::Tuple
    kwargs::Tuple
    fis::Tuple
end

Shader() = Shader((),(),())

function Shader(fum::FractalUserMethod)
    return Shader((fum.fx,), (fum.kwargs,), (fum.fis,))
end

function Shader(fums::Tuple)
    if length(fums) == 0
        error("No FractalUserMethod provided!")
    elseif length(fums) == 1
        return Shader(fums[1])
    else
        # recursive
        shader = Shader()
        for i = 1:length(fums)
            shader = Shader(shader, Shader(fums[i]))
        end

        return shader
    end
end

function Shader(a::Shader, b::Shader)
    return Shader((a.fxs..., b.fxs...),
                  (a.kwargs..., b.kwargs...),
                  (a.fis..., b.fis...))
end

function Shader(shaders::Vector{Shader})
    shader = shaders[1]
    for i = 2:length(shaders)
        shader = Shader(shader, shaders[i])
    end

    return shader
end
