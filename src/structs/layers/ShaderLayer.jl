export ShaderLayer

mutable struct ShaderLayer <: AbstractLayer
    shader::Shader
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    params::NamedTuple
end

function ShaderLayer(shader::Shader, s; ArrayType = Array, FloatType = Float32,
                     numcores = 4, numthreads = 256)
    return ShaderLayer(shader,
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), s)),
                       params(ShaderLayer; ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           numcores = numcores,
                                           numthreads = numthreads))
end

function ShaderLayer(fum::FractalUserMethod, s; ArrayType = Array,
                     FloatType = Float32, numcores = 4, numthreads = 256)
    return ShaderLayer(Shader(fum),
                       ArrayType(fill(RGBA(FloatType(0),0,0,0), s)),
                       params(ShaderLayer; ArrayType = ArrayType,
                                           FloatType = FloatType,
                                           numcores = numcores,
                                           numthreads = numthreads))
end
