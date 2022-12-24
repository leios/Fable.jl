export ShaderLayer

mutable struct ShaderLayer <: AbstractLayer
    shader::Shader
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    position::Tuple
    size::Tuple
    ppu::Int
    params::NamedTuple
end

function ShaderLayer(shader::Shader;
                     size = (0.9, 1.6),
                     position = (0.0, 0.0),
                     ppu = 1200,
                     ArrayType = Array,
                     FloatType = Float32,
                     numcores = 4,
                     numthreads = 256)
    res = (ceil(Int, size[1]*ppu), ceil(Int, size[2]*ppu))

    return ShaderLayer(shader,
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), res)),
                       position,
                       size,
                       ppu,
                       params(ColorLayer;
                              ArrayType = ArrayType,
                              FloatType = FloatType,
                              numcores = numcores,
                              numthreads = numthreads))

end

function ShaderLayer(fum::FractalUserMethod;
                     size = (0.9, 1.6),
                     position = (0.0, 0.0),
                     ppu = 1200,
                     ArrayType = Array,
                     FloatType = Float32,
                     numcores = 4,
                     numthreads = 256)
    res = (size[1]*ppu, size[2]*ppu)

    return ShaderLayer(Shader(fum),
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), res)),
                       position,
                       size,
                       ppu,
                       params(ColorLayer;
                              ArrayType = ArrayType,
                              FloatType = FloatType,
                              numcores = numcores,
                              numthreads = numthreads))

end
