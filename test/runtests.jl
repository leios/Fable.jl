using Test
using KernelAbstractions
using Fae
using Images

ArrayTypes = [Array]
using CUDA
if has_cuda_gpu()
    using CUDAKernels
    CUDA.allowscalar(false)
    push!(ArrayTypes, CuArray)
end

using AMDGPU
if has_rocm_gpu()
    using ROCKernels
    AMDGPU.allowscalar(false)
    push!(ArrayTypes, ROCArray)
end


include("histogram_tests.jl")
include("random_tests.jl")
include("chaos_tests.jl")
include("layering_tests.jl")

function run_tests(ArrayTypes)
    for ArrayType in ArrayTypes
        histogram_testsuite(ArrayType)
        random_testsuite(ArrayType)
        # Note: causes system crashes on AMD
        if !(ArrayType <: ROCArray)
            chaos_testsuite(ArrayType)
        end
        layering_testsuite(ArrayType)
    end
end

run_tests(ArrayTypes)
