module Fable

using KernelAbstractions
using KernelAbstractions: @atomic, @kernel, synchronize, get_backend

# re-exporting
export @kernel, synchronize, get_backend

using ImageIO
using FileIO
using FileIO: save
export save

using VideoIO
using FixedPointNumbers # for N0f8 output for VideoIO

using Colors
using Colors: RGBA, RGB
export RGBA, RGB

# Interfaces
include("structs/point.jl")
include("structs/camera.jl")

# Utilities
include("utils/geometries.jl")

# Objects
include("objects.jl")

end # module
