export ColorLayer

mutable struct ColorLayer <: AbstractLayer
    color::Union{RGB, RGBA}
    canvas::Union{Array{C}, CuArray{C}, ROCArray{C}} where C <: RGBA
    position::Tuple
    size::Tuple
    ppu::Int
    params::NamedTuple
end

function ColorLayer(c::CT;
                    size = (0.9, 1.6),
                    position = (0.0, 0.0),
                    ppu = 1200,
                    ArrayType = Array,
                    FloatType = Float32,
                    numcores = 4,
                    numthreads = 256) where CT <: Union{RGB, RGBA}
    res = (size[1]*ppu, size[2]*ppu)
    if isa(c, RGB)
        c = RGBA(c)
    end

    c = RGBA{FloatType}(c)
    return ColorLayer(c,
                      ArrayType(fill(c, res)),
                      position,
                      size,
                      ppu,
                      params(ColorLayer;
                             ArrayType = ArrayType,
                             FloatType = FloatType,
                             numcores = numcores,
                             numthreads = numthreads))

end
