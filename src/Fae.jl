module Fae

using KernelAbstractions
using CUDA
using CUDAKernels

using Images

# KA kernels
include("histogram.jl")

# Fractal flame structures
include("structs/flame_structs.jl")
include("structs/hutchinson.jl")

# Operations
include("simple_rng.jl")
include("transformations.jl")
include("flames.jl")
include("fractal_flame.jl")
include("image_tools.jl")

end # module
