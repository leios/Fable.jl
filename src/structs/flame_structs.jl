export Pixels

# Right now, points just holds positions... Probably can remove this abstraction
mutable struct Points
    positions::Union{Array{}, CuArray{}} where T <: AbstractFloat

end

function Points(n::Int;AT=Array,dims=2,FT=Float64,
                bounds=[-i/i + (j-1)*2 for i=1:3, j=1:2])
    rnd_array = AT(rand(FT,n,dims))
    for i = 1:dims
        rnd_array[:,i] .= rnd_array[:,i] .* (bounds[i,2] - bounds[i,1]) .+
                          bounds[i,1]
    end
    Points(rnd_array)
end

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct Pixels
    values::Union{Array{I}, CuArray{I}} where I <: Integer
    reds::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
end

Pixels(s; AT=Array, FT = Float64) = Pixels(AT(zeros(Int,s)), AT(zeros(FT, s)),
                                           AT(zeros(FT, s)), AT(zeros(FT, s)))
