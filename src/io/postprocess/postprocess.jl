export postprocess!, intensity, perceptive_intensity, simple_intensity

function postprocess!(layer::AL) where AL <: AbstractLayer
    for i = 1:length(layer.postprocessing_steps)
        if !layer.postprocessing_steps[i].initialized
            @info("initializing " *
                  string(typeof(layer.postprocessing_steps[i])) * "!")
            initialize!(layer.postprocessing_steps[i], layer)
        end
        layer.postprocessing_steps[i].op(layer, layer.postprocessing_steps[i])
    end
end

@inline function clip(c::CT, val::Number) where CT <: RGB
    return CT(min(c.r, val), min(c.g, val), min(c.b, val))
end

@inline function clip(c::CT, val::Number) where CT <: RGBA
    return CT(min(c.r, val), min(c.g, val), min(c.b, val), min(c.alpha, val))
end

@inline function clip(c::Number, val::Number)
    return min(c, val)
end

@inline function intensity(c::CT;
                           i_func = simple_intensity
                          ) where CT <: Union{RGB, RGBA}
    return i_func(c)
end

@inline function perceptive_intensity(c::Number)
    return c
end

@inline function perceptive_intensity(c::CT) where CT <: Union{RGB}
    return (0.21 * c.r) + (0.72 * c.g) + (0.07 * c.b)
end

@inline function perceptive_intensity(c::CT) where CT <: Union{RGBA}
    return c.alpha * ((0.21 * c.r) + (0.72 * c.g) + (0.07 * c.b))
end

@inline function simple_intensity(c::Number)
    return c
end

@inline function simple_intensity(c::CT) where CT <: Union{RGB}
   return (c.r/3) + (c.g/3) + (c.b/3)
end

@inline function simple_intensity(c::CT) where CT <: Union{RGBA}
   return c.alpha * ((c.r/3) + (c.g/3) + (c.b/3))
end
