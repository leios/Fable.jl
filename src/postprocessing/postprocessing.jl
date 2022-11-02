export zero!

@kernel function zero_kernel!(pix_values, pix_reds, pix_greens, pix_blues)
    tid = @index(Global, Cartesian)
    pix_values[tid] = 0
    pix_reds[tid] = 0
    pix_greens[tid] = 0
    pix_blues[tid] = 0
end

function zero!(a::Array{T}) where T <: Union{RGB, RGB{N0f8}}
    a[:] .= RGB(0)
end

function zero!(pix; numthreads = 256, numcores = 4)
    
    if isa(pix.reds, Array)
        kernel! = zero_kernel!(CPU(), numcores)
    elseif has_cuda_gpu() && isa(pix.reds, CuArray)
        kernel! = zero_kernel!(CUDADevice(), numthreads)
    elseif has_rocm_gpu() && isa(pix.reds, ROCArray)
        kernel! = zero_kernel!(ROCDevice(), numthreads)
    end

    kernel!(pix.values, pix.reds, pix.greens, pix.blues,
            ndrange = size(pix.values))

end

function find_point!(tile, bin_widths, tid, bounds, lid)

    tile[lid,2] = bounds[2] + (tid[2]+0.5)*bin_widths[2]
    tile[lid,1] = bounds[1] + (tid[1]+0.5)*bin_widths[1]
    
end
