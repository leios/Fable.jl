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
include("object_tests.jl")

# Example testsuite is flaky, but can be run locally.
#include("example_tests.jl")

function run_tests(ArrayTypes)
    for ArrayType in ArrayTypes
        histogram_testsuite(ArrayType)
        random_testsuite(ArrayType)

        layering_testsuite(ArrayType)
        chaos_testsuite(ArrayType)
        object_testsuite(ArrayType)

        # Note: Passes locally, but not when running Pkg.test (#5)
        #example_testsuite(ArrayType)
    end
end

run_tests(ArrayTypes)
