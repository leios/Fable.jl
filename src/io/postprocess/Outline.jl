export Outline

struct Outline <: AbstractPostProcess
    op::Function
    gauss_filter::Filter
    sobel::Sobel
    clip::Clip
end

function Outline(; linewidth = 1,
                   color = RGBA(1.0, 1.0, 1.0, 1.0),
                   intensity_function = simple_intensity,
                   clip_op = >,
                   threshold = 0.5,
                   ArrayType = Array,
                   sigma = 0.25,
                   canvas_size = (1080, 1920),
                   ) where CT <: Union{RGB, RGBA}
    sobel = Sobel(; color = RGBA(1.0, 1.0, 1.0, 1.0),
                    canvas_size = canvas_size,
                    ArrayType = ArrayType)
    gauss_filter = Blur(; color = RGBA(1.0, 1.0, 1.0, 1.0),
                          filter_size = 3*linewidth,
                          ArrayType = ArrayType,
                          sigma = sigma)
    clip = Clip(; color = color, threshold = threshold)
    return Outline(outline!, gauss_filter, sobel, clip)
end

function outline!(layer::AL, outline_params::Outline) where AL <: AbstractLayer
    filter!(layer, outline_params.gauss_filter)
    sobel!(layer, outline_params.sobel)
    clip!(layer, outline_params.clip)
end
