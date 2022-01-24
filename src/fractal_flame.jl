#TODO: 1. Super sampling must be implemented by increasing the number of bins 
#         before sampling down. Gamma correction at that stage
#TODO: Parallelize with large number of initial points
#TODO: Allow Affine transforms to have a time variable and allow for 
#      supersampling across time with different timesteps all falling into the
#      same bin -- might require 2 buffers: one for log of each step, another
#      for all logs
#TODO: think about directional motion blur
# Example H:
# H = FFlamify.Hutchinson(
#   [FFlamify.swirl, FFlamify.heart, FFlamify.polar, FFlamify.horseshoe],
#   [RGB(0,1,0), RGB(0,0,1), RGB(1,0,1), RGB(1,0,0)],
#   [0.25, 0.25, 0.25, 0.25])
function fractal_flame(H::Hutchinson, n::Int, ranges, res; dims=2,
                       filename="check.png", gamma = 2.2, A_set = [],
                       numthreads = 256, numcores = 4)
    pts = Points(n; dims = dims)

    final_f = polar
    final_color = RGB(1,0,0)

    if length(A_set) > 0
        final_affine = affine_rand()
    end
    for i = 1:n
        if i > 1
            chosen = choose_fid(H)
            f = H.f_set[chosen]
            #println(chosen)

            if do_affine
                points[i] = affine(affine_set[chosen], points[i])
            end

            points[i] = f(points[i-1])
            points[i] = Point(points[i].x, points[i].y, H.clr_set[chosen])
        end

        transformed_color = mix_color(points[i].c, final_color)

        if do_affine
            points[i] = affine(final_affine, points[i])
        end

        points[i] = final_f(points[i])
        points[i] = Point(points[i].x, points[i].y, transformed_color)
    end

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
