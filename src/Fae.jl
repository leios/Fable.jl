module Fae

using KernelAbstractions
using KernelAbstractions: @atomic
using CUDA
if has_cuda_gpu()
    using CUDAKernels
end

using AMDGPU
if has_rocm_gpu()
    using ROCKernels
end

using MacroTools
using DataStructures
using LinearAlgebra

using Images
using VideoIO


# KA kernels
include("math/histogram.jl")

# Fractal flame structures
include("structs/fractal_input.jl")
include("structs/fractal_user_methods.jl")
include("fums/colors.jl")
include("structs/fractal_operators.jl")
include("structs/flame_structs.jl")
include("structs/fractal_executable/fractal_executable.jl")
include("structs/fractal_executable/hutchinson.jl")
include("structs/fractal_executable/shader.jl")

# Operations
include("math/simple_rng.jl")
include("fums/flames.jl")
include("fums/smears.jl")

# Objects
include("objects/rectangle.jl")
include("objects/circle.jl")
include("objects/triangle.jl")
include("objects/barnsley.jl")
include("objects/lollipeople.jl")

# 
include("io/io_structs.jl")
include("io/io_tools.jl")

# Main file
include("run/fractal_flame.jl")
include("run/shader.jl")

end # module
