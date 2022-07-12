module Fae

using KernelAbstractions
using KernelAbstractions: @atomic
using CUDA
using CUDAKernels
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
include("structs/fractal_executable.jl")

# Operations
include("math/simple_rng.jl")
include("fums/flames.jl")
include("fums/smears.jl")

# Objects
include("objects/rectangle.jl")
include("objects/circle.jl")
include("objects/triangle.jl")
include("objects/barnsley.jl")

# Postprocessing
include("postprocessing/io_structs.jl")
include("postprocessing/postprocessing.jl")
include("postprocessing/io_tools.jl")

# Main file
include("fractal_flame.jl")

# Lollipeople
include("objects/lollipeople.jl")

end # module
