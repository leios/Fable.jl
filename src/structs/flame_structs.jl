# Right now, points just holds positions... Probably can remove this abstraction
mutable struct Points
    positions::Union{Array{}, CuArray{}, ROCArray{}} where T <: AbstractFloat

end

function Points(n::Int; ArrayType=Array, dims=2, FloatType=Float32,
                bounds=[-i/i + (j-1)*2 for i=1:3, j=1:2])
    rnd_array = ArrayType(rand(FloatType,n,dims))
    for i = 1:dims
        rnd_array[:,i] .= rnd_array[:,i] .* (bounds[i,2] - bounds[i,1]) .+
                          bounds[i,1]
    end
    Points(rnd_array)
end
