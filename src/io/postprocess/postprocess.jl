export postprocess!, intensity, perspective_intensity, simple_intensity

function postprocess!(layer::AL) where AL <: AbstractLayer
    for postprocess in layer.postprocessing_steps
        postprocess.op(layer, postprocess)
    end
end

@inline function intensity(c::CT;
                           i_func = simple_intensity
                          ) where CT <: Union{RGB, RGBA}
    return i_func(c)
end

@inline function perceptive_intensity(c::CT) where CT <: Union{RGB}
    return (0.21 * c.r) + (0.72 * c.g) + (0.07 * c.b)
end

@inline function perceptive_intensity(c::CT) where CT <: Union{RGBA}
    return c.alpha * ((0.21 * c.r) + (0.72 * c.g) + (0.07 * c.b))
end

@inline function simple_intensity(c::CT) where CT <: Union{RGB}
   return (c.r + c.g + c.b)/3
end

@inline function simple_intensity(c::CT) where CT <: Union{RGBA}
   return c.alpha * (c.r + c.g + c.b)/3
end
