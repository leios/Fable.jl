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
