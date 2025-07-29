module Fable

using KernelAbstractions
using KernelAbstractions: @atomic

using Unitful

using ImageIO
using FileIO
using VideoIO
using Colors
using FixedPointNumbers # for N0f8 output for VideoIO

# Constants
global OUTPUT = true
set_output(tf) = (global OUTPUT = tf)

# Interfaces
include("structs/time.jl")
include("structs/point.jl")
include("structs/camera.jl")

# Utilities
include("utils/geometries.jl")
include("utils/histogram.jl")

# Objects
include("objects.jl")

end # module
