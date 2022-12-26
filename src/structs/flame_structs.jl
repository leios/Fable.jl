# Right now, points just holds positions... Probably can remove this abstraction
mutable struct Points
    positions::Union{Array{}, CuArray{}, ROCArray{}} where T <: AbstractFloat

end

function Points(n::Int; ArrayType=Array, dims=2, FloatType=Float32,
                bounds=find_bounds((0,0), (2,2)))
    rnd_array = ArrayType(rand(FloatType,n,dims))
    for i = 1:dims
        rnd_array[:,i] .= rnd_array[:,i] .* (bounds[i*2] - bounds[i*2-1]) .+
                          bounds[i*2-1]
    end
    Points(rnd_array)
end
