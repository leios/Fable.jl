module FFlamify

using KernelAbstractions
using CUDA
using CUDAKernels

using Images

# KA kernels
include("histogram.jl")

# Fractal flame structures
include("flame_structs.jl")
include("hutchinson.jl")

# Operations
include("transformations.jl")
#include("flames.jl")
#include("fractal_flame.jl")
#include("image_tools.jl")

end # module
