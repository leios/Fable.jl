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
using Unitful

using Images
using VideoIO

# Constants
global OUTPUT = true
set_output(tf) = (global OUTPUT = tf)

# Interfaces
include("structs/time.jl")

# KA kernels
include("math/histogram.jl")

# Fractal flame structures
include("structs/fractal_input.jl")
include("structs/fractal_user_methods.jl")
include("fums/shaders.jl")
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

# IO
include("structs/layers/layers.jl")
include("io/postprocess/postprocess.jl")
include("structs/layers/FractalLayer.jl")
include("structs/layers/ColorLayer.jl")
include("structs/layers/ImageLayer.jl")
include("structs/layers/ShaderLayer.jl")
include("structs/VideoParams.jl")
include("io/io_tools.jl")

# PostProcessing
include("io/postprocess/Clip.jl")
include("io/postprocess/Filter.jl")
include("io/postprocess/Sobel.jl")
include("io/postprocess/Outline.jl")

# Main file
include("run/run.jl")
include("run/fractal_flame.jl")
include("run/shader.jl")
include("run/color.jl")

end # module
