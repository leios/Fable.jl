function identity(p::T) where T <: Union{Array{Float64}, CuArray{Float64}}
    return p
end

function sinusoidal(p::T) where T <: Union{Array{Float64}, CuArray{Float64}}
    return sin.(p)
end

function polar(p::T) where T <: Union{Array{Float64}, CuArray{Float64}}
    r = sqrt(sum(p[1]*p[1] + p[2]*p[2]))
    theta = atan(p.x, p.y)

    return Point(theta/pi,r-1)
end

function horseshoe(p::T) where T <: Union{Array{Float64}, CuArray{Float64}}
    r = sqrt(p[1]*p[1] + p[2]*p[2])
    if r < 0.001
        r = 0.001
    end

    return Point((p[1]-p[2])*(p[1]+p[2])/r, 2*p[1]*p[2]/r)
end

function heart(p::T) where T <: Union{Array{Float64}, CuArray{Float64}}
    r = sqrt(p[1]*p[1] + p[2]*p[2])
    theta = atan(p[1], p[2])
    return Point(r*sin(theta*r),
                 -r*cos(theta*r))
end

function rotate(p::T;
                theta = 0.5) where T <: Union{Array{Float64}, CuArray{Float64}}

    return Point(p[1]*sin(theta) - p[2]*cos(theta),
                 p[1]*cos(theta) + p[2]*sin(theta))
end

function swirl(p::T) where T <: Union{Array{Float64}, CuArray{Float64}}
    r = sqrt(p[1]*p[1] + p[2]*p[2])
    return Point(p[1]*sin(r*r) - p[2]*cos(r*r),
                 p[1]*cos(r*r) + p[2]*sin(r*r))
end

function sierpinski(point::T, shape_vertex::T) where
                    T <: Union{Array{Float64}, CuArray{Float64}}
    return 0.5*(point .+ shape_vertex)
end
