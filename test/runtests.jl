using Test
using KernelAbstractions
using Fable
using Colors

ArrayTypes = [Array]
using CUDA
if has_cuda_gpu()
    CUDA.allowscalar(false)
    push!(ArrayTypes, CuArray)
end

using AMDGPU
if has_rocm_gpu()
    AMDGPU.allowscalar(false)
    push!(ArrayTypes, ROCArray)
end

function run_tests(ArrayTypes)
    for ArrayType in ArrayTypes
    end
end

run_tests(ArrayTypes)
