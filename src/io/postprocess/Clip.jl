export Clip

struct Clip <: AbstractPostProcess
    op::Function
    threshold::Number
    color::CT where CT <: Union{RGB, RGBA}
end

Clip(; threshold = 0.5, color = RGB(0,0,0)) = Clip(clip!, threshold, color)

function clip!(layer::AL) where AL <: AbstractLayer
end

@kernel clip_kernel!(canvas, threshold)
end
