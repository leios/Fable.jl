mutable struct Hutchinson
    f_set::Vector{Any}
    color_set::Array{Float64, 4}
    prob_set::Vector{Float64}
end

mutable struct Points
    positions::Array{Float64}
    colors::Array{Float64, 4}
end

Points(n;dims=2) = Points(zeros(n,dims),zeros(n,4))

mutable struct Pixel
    val::Float64
    c::Union{RGB, RGBA}
end

Pixel(x) = Pixel(x, RGB(0))
