mutable struct Hutchinson
    f_set::Vector{Any}
    color_set::Union{Array{Float64, 4}, CuArray{Float64}}
    prob_set::Union{Vector{Float64}, CuArray{Float64}}
end

mutable struct Points
    positions::Union{Array{Float64}, CuArray{Float64}}
    colors::Union{Array{Float64, 4}, CuArray{Float64, 4}}
end

Points(n;dims=2) = Points(zeros(n,dims),zeros(n,4))

mutable struct Pixels
    values::Union{Vector{Float64}, CuArray{Float64}}
    colors::Union{Array{Float64, 4}, CuArray{Float64, 4}}
end

Pixel(x) = Pixel(x, RGB(0))
