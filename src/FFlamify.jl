module FFlamify

using Images

include("flame_structs.jl")
include("hutchinson.jl")

include("transformations.jl")
include("flames.jl")
include("fractal_flame.jl")
include("image_tools.jl")

end # module
