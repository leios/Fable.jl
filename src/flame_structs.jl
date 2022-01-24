mutable struct Hutchinson
    f_set::NTuple
    color_set::Union{Array{Float64, 4}, CuArray{Float64}}
    prob_set::Union{Vector{Float64}, CuArray{Float64}}
end

mutable struct Points
    positions::Union{Array{Float64}, CuArray{Float64}}
end

Points(n::Int;dims=2) = Points(zeros(n,dims))

mutable struct Pixels
    values::Union{Vector{Int}, CuArray{Int}}
    reds::Union{Array{Float64}, CuArray{Float64}}
    greens::Union{Array{Float64}, CuArray{Float64}}
    blues::Union{Array{Float64}, CuArray{Float64}}
end

Pixel(x) = Pixel(x, RGB(0))
