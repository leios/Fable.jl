export Outline

struct Outline <: AbstractPostProcess
    op::Function
    threshold::Number
    gauss_filter::AT where AT <: Union{Array, CuArray, ROCArray}
    sobel_filter::AT where AT <: Union{Array, CuArray, ROCArray}
    color::CT where CT <: Union{RGB, RGBA}
end

function Outline(color::CT; linewidth = 1) where CT <: Union{RGB, RGBA}
end

function outline!(layer::AL, outline_params::Outline) where AL <: AbstractLayer
end

@kernel function ouline_kernel!(canvas, gauss_filter, sobel_filter,
                                threshold, color)
end
