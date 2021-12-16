#TODO: 1. Super sampling must be implemented by increasing the number of bins 
#         before sampling down. Gamma correction at that stage
#      2. Density estimation with dynamic kernel related to the number of points
#         in the bins. Lower points = broader kernel (more blurring)
#TODO: Parallelize with large number of initial points
#TODO: Allow Affine transforms to have a time variable and allow for 
#      supersampling across time with different timesteps all falling into the
#      same bin -- might require 2 buffers: one for log of each step, another
#      for all logs
#TODO: think about directional motion blur
function flame(n::Int, ranges, res; filename="check.png", gamma = 2.2,
               do_affine = false)
    points = [Point(0, 0) for i = 1:n]

    # initializing the first point
    #points[1] = Point(0.1, 0.1)
    points[1] = Point(-0.5*(ranges[1]) + rand()*ranges[1],
                      -0.5*(ranges[2]) + rand()*ranges[2])
    

    # TODO: allow for each function in function set to have a different
    #       probability
    f_set = [swirl, polar, heart, horseshoe]
    color_set = [RGB(0,1,0), RGB(0,0,1), RGB(1,0,1), RGB(1,0,0)]
    if do_affine
        affine_set = [affine_rand(), affine_rand(),
                      affine_rand(), affine_rand()]
    end

    final_f = sinusoidal
    final_color = RGB(0,1,1)

    if do_affine
        final_affine = affine_rand()
    end
    for i = 1:n
        if i > 1
            chosen = rand(1:length(f_set))
            f = f_set[chosen]

            if do_affine
                points[i] = affine(affine_set[chosen], points[i])
            end

            points[i] = f(points[i-1])
            points[i] = Point(points[i].x, points[i].y, color_set[chosen])
        end

        transformed_color = mix_color(points[i].c, final_color)

        if do_affine
            points[i] = affine(final_affine, points[i])
        end

        points[i] = final_f(points[i])
        points[i] = Point(points[i].x, points[i].y, transformed_color)
    end

    println("Time for write_image()")
    @time write_image(points, ranges, res, filename, gamma = gamma)

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
