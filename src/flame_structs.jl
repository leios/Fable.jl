# Struct for function composition
function U(args...)
end

mutable struct Hutchinson
    f_set::Expr
    color_set::Union{Array{T,2}, CuArray{T,2}} where T <: AbstractFloat
    prob_set::Union{NTuple, Tuple}
end

# This is a constructor for when people read in an array of arrays for colors
function Hutchinson(f_set, color_set::Array{A}, prob_set;
                    AT = Array, FT = Float64) where A <: Array

    fnum = length(f_set.args)-1
    temp_colors = zeros(FT,fnum,4)

    if !isapprox(sum(prob_set),1)
        println("probability set != 1, resetting to be equal probability...")
        prob_set = Tuple(1/fnum for i = 1:fnum)
    end

    for i = 1:4
        for j = 1:length(color_set)
            temp_colors[j,i] = color_set[j][i]
        end
    end

    return Hutchinson(f_set, AT(temp_colors), prob_set)
end

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

Pixel(x) = Pixel(x, RGB(0))
