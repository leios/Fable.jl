function linear(p::Point)
    return p
end

function polar(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    theta = atan(p.x, p.y)

    polar_color = RGB(0,0,1)
    return Point(theta/pi,r-1)
end

function horseshoe(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    if r < 0.001
        r = 0.001
    end
    horseshoe_color = RGB(0,1,1)

    return Point((p.x-p.y)*(p.x+p.y)/r, 2*p.x*p.y/r, horseshoe_color)
end

function heart(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    theta = atan(p.x, p.y)
    heart_color = RGB(1,0,1)
    return Point(r*sin(theta*r),
                 -r*cos(theta*r),
                 heart_color)
end

function rotate(p::Point; theta = 0.5)
    swirl_color = RGB(0,0,1)
    return Point(p.x*sin(theta) - p.y*cos(theta),
                 p.x*cos(theta) + p.y*sin(theta),
                 swirl_color)
end

function swirl(p::Point)
    r = sqrt(p.x*p.x + p.y*p.y)
    swirl_color = RGB(0,0,1)
    return Point(p.x*sin(r*r) - p.y*cos(r*r),
                 p.x*cos(r*r) + p.y*sin(r*r),
                 swirl_color)
end

function sierpinski(point::Point, shape_vertices::Vector{Point})
    shape_vertex = shape_vertices[rand(1:length(shape_vertices))]
    flame_color = RGB(rand(), rand(), rand())
    return Point(0.5*(point.x + shape_vertex.x),
                 0.5*(point.y + shape_vertex.y),
                 flame_color)
end

function sierpinski(point::Array{Float64}, shape_vertices::Array{Float64})
    shape_vertex = shape_vertices[rand(1:length(shape_vertices))]
    return 0.5*(point .+ shape_vertex)
end
