export ShaderLayer

mutable struct ShaderLayer <: AbstractLayer
    shader::Shader
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    position::Tuple
    world_size::Tuple
    ppu::Number
    params::NamedTuple
    postprocessing_steps::Vector{APP} where APP <: AbstractPostProcess
end

function ShaderLayer(shader::Shader;
                     postprocessing_steps = Vector{AbstractPostProcess}([]),
                     world_size = (0.9, 1.6),
                     position = (0.0, 0.0),
                     ppu = 1200,
                     ArrayType = Array,
                     FloatType = Float32,
                     numcores = 4,
                     numthreads = 256)
    res = (ceil(Int, world_size[1]*ppu), ceil(Int, world_size[2]*ppu))

    return ShaderLayer(shader,
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), res)),
                       position,
                       world_size,
                       ppu,
                       params(ColorLayer;
                              ArrayType = ArrayType,
                              FloatType = FloatType,
                              numcores = numcores,
                              numthreads = numthreads),
                       postprocessing_steps)

end

function ShaderLayer(fums::Union{FractalUserMethod, Tuple};
                     postprocessing_steps = Vector{AbstractPostProcess}([]),
                     world_size = (0.9, 1.6),
                     position = (0.0, 0.0),
                     ppu = 1200,
                     ArrayType = Array,
                     FloatType = Float32,
                     numcores = 4,
                     numthreads = 256)
    res = (ceil(Int, world_size[1]*ppu), ceil(Int, world_size[2]*ppu))

    return ShaderLayer(Shader(fums),
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), res)),
                       position,
                       world_size,
                       ppu,
                       params(ColorLayer;
                              ArrayType = ArrayType,
                              FloatType = FloatType,
                              numcores = numcores,
                              numthreads = numthreads),
                       postprocessing_steps)

end
