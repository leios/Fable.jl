#=
function linear(p::Point)
    return p
end

function sinusoidal(p::Point)
    return Point(sin(p.x), sin(p.y))
end

function polar(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    theta = atan(p.x, p.y)

    return Point(theta/pi,r-1)
end

function horseshoe(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    if r < 0.001
        r = 0.001
    end

    return Point((p.x-p.y)*(p.x+p.y)/r, 2*p.x*p.y/r)
end

function heart(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    theta = atan(p.x, p.y)
    return Point(r*sin(theta*r),
                 -r*cos(theta*r))
end

function rotate(p::Point; theta = 0.5)
    return Point(p.x*sin(theta) - p.y*cos(theta),
                 p.x*cos(theta) + p.y*sin(theta))
end

function swirl(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    return Point(p.x*sin(r*r) - p.y*cos(r*r),
                 p.x*cos(r*r) + p.y*sin(r*r))
end

function sierpinski(point::Point, shape_vertices::Vector{Point})
    shape_vertex = shape_vertices[rand(1:length(shape_vertices))]
    return Point(0.5*(point.x + shape_vertex.x),
                 0.5*(point.y + shape_vertex.y))
end
=#

function sierpinski(point::Array{Float64}, shape_vertices::Array{Float64})
    shape_vertex = shape_vertices[rand(1:length(shape_vertices))]
    return 0.5*(point .+ shape_vertex)
end
