export ColorLayer

mutable struct ColorLayer <: AbstractLayer
    color::Union{RGB, RGBA}
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    params::NamedTuple
end

function ColorLayer(c::CT, s; ArrayType = Array, FloatType = Float32,
                    numcores = 4, numthreads = 256) where CT<:Union{RGB, RGBA}
    if isa(c, RGB)
        c = RGBA(c)
    end

    c = RGBA{FloatType}(c)
    return ColorLayer(c, ArrayType(fill(c, s)), params(ColorLayer;
                                                ArrayType = ArrayType,
                                                FloatType = FloatType,
                                                numcores = numcores,
                                                numthreads = numthreads))
end
