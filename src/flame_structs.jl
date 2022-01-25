# Struct for function composition
mutable struct Hutchinson
    f_set::Union{NTuple, Tuple}
    color_set::Union{Array{T,2}, CuArray{T,2}} where T <: AbstractFloat
    prob_set::Union{NTuple, Tuple}
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(f_set, color_set::Array{A}, prob_set;
                    AT = Array, FT = Float64) where A <: Array

    temp_colors = zeros(FT,4,length(color_set))

    for i = 1:4
        for j = 1:length(color_set)
            temp_colors[i,j] = color_set[j][i]
        end
    end

    return Hutchinson(f_set, AT(temp_colors), prob_set)
end

# Right now, points just holds positions... Probably can remove this abstraction
mutable struct Points
    positions::Union{Array{}, CuArray{}} where T <: AbstractFloat

end

Points(n::Int;AT=Array,dims=2) = Points(AT(zeros(n,dims)))

# Note: the rgb components needed to be spread into separate arrays for indexing
#       reasons in the KA kernels
mutable struct Pixels
    values::Union{Array{I}, CuArray{I}} where I <: Integer
    reds::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    greens::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
    blues::Union{Array{T}, CuArray{T}} where T <: AbstractFloat
end

Pixels(s; AT=Array) = Pixels(AT(zeros(Int,s)), AT(zeros(s)),
                             AT(zeros(s)), AT(zeros(s)))

Pixel(x) = Pixel(x, RGB(0))
