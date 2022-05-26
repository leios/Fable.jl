module Fae

using KernelAbstractions
using CUDA
using CUDAKernels
using MacroTools
using DataStructures
using LinearAlgebra

using Images
using VideoIO

using Atomix: @atomic

# KA kernels
include("histogram.jl")

# Fractal flame structures
include("structs/fractal_input.jl")
include("structs/fractal_user_methods.jl")
include("colors.jl")
include("structs/fractal_operators.jl")
include("structs/flame_structs.jl")
include("structs/fractal_executable.jl")

# Operations
include("simple_rng.jl")
include("transformations.jl")
include("flames.jl")

# Objects
include("objects/rectangle.jl")
include("objects/circle.jl")
include("objects/sierpinski.jl")
include("objects/barnsley.jl")

# Postprocessing
include("postprocessing/io_structs.jl")
include("postprocessing/postprocessing.jl")
include("postprocessing/io_tools.jl")

# Main file
include("fractal_flame.jl")

end # module
