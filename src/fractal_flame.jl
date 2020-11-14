# TODO: - set affine tranform for every flame
#       - Create function to do affine tranform and flame at the same time
function flame(n::Int, ranges, res; filename="check.png", gamma = 2.2)
    points = [Point(0, 0) for i = 1:n]

    # initializing the first point
    #points[1] = Point(0.1, 0.1)
    points[1] = Point(-0.5*(ranges[1]) + rand()*ranges[1],
                      -0.5*(ranges[2]) + rand()*ranges[2])
    

    # TODO: allow for each function in function set to have a different
    #       probability
    f_set = [swirl, polar, heart, horseshoe]
    for i = 2:n
        f = rand(f_set)
        points[i] = f(points[i-1])
    end

    # TODO: do final transform... Chosen at function call

    write_image(points, ranges, res, filename, gamma = gamma)

end

function chaos_game(n::Int, ranges)
    points = [Point(0, 0) for i = 1:n]

    triangle_points = [Point(-1, -1), Point(1,-1), Point(0, sqrt(3)/2)]
    [points[1].x, points[1].y] .= -0.5.*(ranges) + rand(2).*ranges

    for i = 2:n
        points[i] = sierpinski(points[i-1], triangle_points)
    end

    return points
end
