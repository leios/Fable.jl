export Outline

mutable struct Outline <: AbstractPostProcess
    op::Function
    gauss_filter::Filter
    sobel::Sobel
    clip::Clip
    initialized::Bool
end

function Outline(; linewidth = 1,
                   color = RGBA(1.0, 1.0, 1.0, 1.0),
                   intensity_function = simple_intensity,
                   clip_op = >,
                   threshold = 0.5,
                   sigma = 0.25,
                   ) where CT <: Union{RGB, RGBA}
    sobel = Sobel()
    gauss_filter = Blur(; filter_size = 3*linewidth, sigma = sigma)
    clip = Clip(; color = color, threshold = threshold, clip_op = clip_op)
    return Outline(outline!, gauss_filter, sobel, clip)
end

function initialize!(o::Outline, layer::AL) where AL <: AbstractLayer
    initialize!(o.gauss_filter, layer)
    initialize!(o.sobel, layer)
    o.initialized = true
end

function outline!(layer::AL, outline_params::Outline) where AL <: AbstractLayer
    filter!(layer, outline_params.gauss_filter)
    sobel!(layer, outline_params.sobel)
    clip!(layer, outline_params.clip)
end
