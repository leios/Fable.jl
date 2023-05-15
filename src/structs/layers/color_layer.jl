export ColorLayer

mutable struct ColorLayer <: AbstractLayer
    color::Union{RGB, RGBA}
    canvas::AT where AT <: AbstractArray
    position::Tuple
    world_size::Tuple
    ppu::Number
    params::NamedTuple
    postprocessing_steps::Vector{APP} where APP <: AbstractPostProcess
end

function ColorLayer(c::CT;
                    postprocessing_steps = Vector{AbstractPostProcess}([]),
                    world_size = (0.9, 1.6),
                    position = (0.0, 0.0),
                    ppu = 1200,
                    ArrayType = Array,
                    FloatType = Float32,
                    numthreads = 256) where CT <: Union{RGB, RGBA}
    res = (ceil(Int,world_size[1]*ppu), ceil(Int,world_size[2]*ppu))
    if isa(c, RGB)
        c = RGBA(c)
    end

    c = RGBA{FloatType}(c)
    return ColorLayer(c,
                      ArrayType(fill(c, res)),
                      position,
                      world_size,
                      ppu,
                      params(ColorLayer;
                             ArrayType = ArrayType,
                             FloatType = FloatType,
                             numthreads = numthreads),
                      postprocessing_steps)

end
