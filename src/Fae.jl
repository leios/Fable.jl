module Fae

using KernelAbstractions
using CUDA
using CUDAKernels
using MacroTools
using DataStructures

using Images
using VideoIO

# KA kernels
include("histogram.jl")

# Fractal flame structures
include("structs/fractal_input.jl")
include("structs/fractal_operators.jl")
include("structs/flame_structs.jl")
include("structs/hutchinson.jl")

# Objects
include("objects/rectangle.jl")
include("objects/circle.jl")
include("objects/sierpinski.jl")

# Operations
include("simple_rng.jl")
include("transformations.jl")
include("flames.jl")
include("fractal_flame.jl")

# postprocessing
include("postprocessing/postprocessing.jl")
include("postprocessing/io_tools.jl")

end # module
