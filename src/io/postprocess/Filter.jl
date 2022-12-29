export Filter, Blur, Sobel

struct Filter <: AbstractPostProcess
    op::Function
    filter::AT where AT <: Union{Array, CuArray, ROCArray}
end

function Blur(; filter_size = 3)
end

function Sobel(; filter_size = 3)
end

function Filter(filter)
end

function filter!(layer::AL) where AL <: AbstractLayer
end

@kernel function filter_kernel!(canvas, filter)
end
